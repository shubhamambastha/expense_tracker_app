import express from 'express';
import { createClient } from '@supabase/supabase-js';
import { createRemoteJWKSet, jwtVerify } from 'jose';

for (const key of ['SUPABASE_URL', 'SUPABASE_ANON_KEY', 'AUTH0_DOMAIN', 'AUTH0_CLIENT_ID']) {
  if (!process.env[key]) throw new Error(`Missing env ${key}`);
}
const { SUPABASE_URL, SUPABASE_ANON_KEY, AUTH0_DOMAIN, AUTH0_CLIENT_ID } = process.env;

const issuer = `https://${AUTH0_DOMAIN}/`;
// Long cache so a JWKS blip at a cache boundary can't 401 everyone; an unknown kid still forces a refetch.
const jwks = createRemoteJWKSet(new URL(`${issuer}.well-known/jwks.json`), { cacheMaxAge: 12 * 60 * 60 * 1000 });

// jose errors that mean "the caller's token is bad". Anything else (JWKS timeout/fetch failure) is our outage.
const TOKEN_ERRORS = new Set([
  'ERR_JWT_EXPIRED', 'ERR_JWT_CLAIM_VALIDATION_FAILED', 'ERR_JWT_INVALID', 'ERR_JWS_INVALID',
  'ERR_JWS_SIGNATURE_VERIFICATION_FAILED', 'ERR_JWKS_NO_MATCHING_KEY', 'ERR_JWKS_MULTIPLE_MATCHING_KEYS',
  'ERR_JOSE_ALG_NOT_ALLOWED', 'ERR_JOSE_NOT_SUPPORTED',
]);

// Bound every Supabase call so a stalled upstream can't pin requests for minutes.
const fetchWithTimeout = (url, init) => fetch(url, { ...init, signal: AbortSignal.timeout(10_000) });

// Columns the client may write. `id` and `user_id` always come from the server.
const COLUMNS = {
  transactions: [
    'kind', 'amount', 'currency_code', 'category', 'counterparty_name', 'note',
    'account_id', 'transfer_to_account_id', 'date', 'is_recurring', 'is_paused',
    'closed_at', 'recurrence_frequency', 'recurrence_start_date',
    'recurrence_end_date', 'reminder_timing',
  ],
  accounts: [
    'name', 'type', 'opening_balance', 'credit_limit', 'statement_day', 'due_day',
    'nickname', 'provider_name', 'notes', 'is_archived', 'linked_account_id',
    'wallet_provider',
  ],
  recurring_events: ['transaction_id', 'occurrence_date', 'event_type', 'snooze_until'],
  category_budgets: ['category_name', 'monthly_limit', 'currency_code'],
  categories: ['name', 'icon', 'sort_order', 'is_default'],
  user_settings: ['default_currency_code', 'preferences', 'onboarding_completed_at', 'updated_at'],
};

const pick = (body, cols) =>
  Object.fromEntries(cols.filter((c) => body && c in body).map((c) => [c, body[c]]));

async function must(query) {
  const { data, error, status } = await query;
  if (error) {
    // PostgREST already picks the right 4xx (bad input 400, conflict 409, RLS 403, rejected JWT 401).
    // .single() matching no row arrives as 406: really "missing, or someone else's".
    error.status = error.code === 'PGRST116' ? 404 : status >= 400 && status < 500 ? status : 500;
    throw error;
  }
  return data;
}

const send = (res, query, status = 200) =>
  must(query).then((data) => res.status(status).json(data));

// Supabase silently caps a response at max_rows (default 1000), so page until a short page.
// ponytail: assumes the project's max_rows >= PAGE; lower PAGE if that setting is ever lowered.
const PAGE = 1000;
async function sendAll(res, query) {
  const rows = [];
  for (;;) {
    // `id` tiebreak keeps page boundaries stable when the sort column has duplicates.
    const page = await must(query().order('id').range(rows.length, rows.length + PAGE - 1));
    rows.push(...page);
    if (page.length < PAGE) return res.json(rows);
  }
}

async function auth(req, res, next) {
  const token = req.get('authorization')?.match(/^Bearer (.+)$/)?.[1];
  if (!token) return res.status(401).json({ error: 'Missing bearer token' });
  try {
    const { payload } = await jwtVerify(token, jwks, {
      issuer,
      audience: AUTH0_CLIENT_ID, // the app sends ID tokens
      algorithms: ['RS256'],
      requiredClaims: ['sub'],
    });
    req.userId = payload.sub;
  } catch (err) {
    if (!TOKEN_ERRORS.has(err.code)) throw err;
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
  // Forward the caller's token so Supabase RLS still applies as a second guard.
  req.db = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    accessToken: async () => token,
    global: { fetch: fetchWithTimeout },
  });
  next();
}

const api = express.Router();
api.use(auth);
api.param('id', (req, res, next, id) =>
  /^\d{1,18}$/.test(id) ? next() : res.status(404).json({ error: 'Not found' }));

const list = (req, table) => req.db.from(table).select().eq('user_id', req.userId);
const updateOwn = (req, table, values) =>
  req.db.from(table).update(values).eq('id', req.params.id).eq('user_id', req.userId).select().single();
const deleteOwn = (req, table) =>
  req.db.from(table).delete().eq('id', req.params.id).eq('user_id', req.userId);
const row = (req, cols, body = req.body) => ({ ...pick(body, cols), user_id: req.userId });

// Transactions
api.get('/transactions', (req, res) =>
  sendAll(res, () => list(req, 'transactions').order('date', { ascending: false })));
api.post('/transactions', (req, res) =>
  send(res, req.db.from('transactions').insert(row(req, COLUMNS.transactions)).select().single(), 201));
api.patch('/transactions/:id', (req, res) =>
  send(res, updateOwn(req, 'transactions', pick(req.body, COLUMNS.transactions))));
api.delete('/transactions/:id', (req, res) => send(res, deleteOwn(req, 'transactions'), 204));

// Recurring events — POST upserts per occurrence, so repeat taps don't duplicate.
api.get('/recurring-events', (req, res) =>
  sendAll(res, () => list(req, 'recurring_events').order('occurrence_date', { ascending: false })));
api.post('/recurring-events', (req, res) =>
  send(res, req.db.from('recurring_events')
    .upsert(row(req, COLUMNS.recurring_events), {
      onConflict: 'user_id,transaction_id,occurrence_date,event_type',
    })
    .select().single(), 201));
api.delete('/recurring-events/:id', (req, res) => send(res, deleteOwn(req, 'recurring_events'), 204));

// Accounts
api.get('/accounts', (req, res) => sendAll(res, () => {
  const query = list(req, 'accounts');
  return (req.query.includeArchived === 'true' ? query : query.eq('is_archived', false)).order('name');
}));
api.post('/accounts', (req, res) =>
  send(res, req.db.from('accounts').insert(row(req, COLUMNS.accounts)).select().single(), 201));
api.patch('/accounts/:id', (req, res) =>
  send(res, updateOwn(req, 'accounts', pick(req.body, COLUMNS.accounts))));
api.delete('/accounts/:id', (req, res) => send(res, deleteOwn(req, 'accounts'), 204));

// Category budgets — POST upserts on (user_id, category_name).
api.get('/budgets', (req, res) => sendAll(res, () => list(req, 'category_budgets').order('category_name')));
api.post('/budgets', (req, res) =>
  send(res, req.db.from('category_budgets')
    .upsert(row(req, COLUMNS.category_budgets), { onConflict: 'user_id,category_name' })
    .select().single()));
api.delete('/budgets/:id', (req, res) => send(res, deleteOwn(req, 'category_budgets'), 204));

// Categories — POST takes one object or an array (default seeding).
for (const [kind, table] of [['expense', 'expense_categories'], ['income', 'income_categories']]) {
  api.get(`/categories/${kind}`, (req, res) =>
    sendAll(res, () => list(req, table).order('sort_order').order('name')));
  api.post(`/categories/${kind}`, async (req, res) => {
    const rows = [].concat(req.body).map((body) => row(req, COLUMNS.categories, body));
    const data = await must(req.db.from(table).insert(rows, { defaultToNull: false }).select());
    res.status(201).json(Array.isArray(req.body) ? data : data[0]);
  });
  // Seeded defaults are never deletable.
  api.delete(`/categories/${kind}/:id`, (req, res) =>
    send(res, deleteOwn(req, table).eq('is_default', false), 204));
}

// User settings — PATCH upserts only the columns sent, so omitted ones keep their value.
api.get('/settings', (req, res) =>
  send(res, req.db.from('user_settings').select().eq('user_id', req.userId).maybeSingle()));
api.patch('/settings', (req, res) =>
  send(res, req.db.from('user_settings').upsert(row(req, COLUMNS.user_settings)).select().single()));

// "Reset My Account": wipes everything except user_settings. Order respects FKs.
// ponytail: not atomic — a mid-way failure leaves a partial wipe; move to a Postgres function if that bites.
api.delete('/data', async (req, res) => {
  for (const table of [
    'recurring_events', 'transactions', 'accounts',
    'category_budgets', 'expense_categories', 'income_categories',
  ]) {
    await must(req.db.from(table).delete().eq('user_id', req.userId));
  }
  res.status(204).end();
});

export const app = express();
app.disable('x-powered-by');
app.use(express.json({ limit: '1mb' }));
app.get('/health', (req, res) => res.send('ok'));
app.use('/v1', api);
app.use((req, res) => res.status(404).json({ error: 'Not found' }));
// Fixed client-facing text: raw Postgres messages name constraints and indexes. Details go to the log.
const MESSAGES = {
  400: 'Invalid request.', 401: 'Invalid or expired token', 403: 'Not allowed.',
  404: 'Not found', 409: 'That already exists or is still in use.', 413: 'Request too large.',
};
app.use((err, req, res, next) => {
  const status = err.status ?? 500;
  if (status >= 500) console.error(err);
  else if (err.code) console.warn(status, err.code, err.message);
  const error = MESSAGES[status] ?? (status >= 500 ? 'Internal server error' : 'Request failed.');
  res.status(status).json({ error, code: err.code });
});
