import { createClient } from '@supabase/supabase-js';
import { SUPABASE_URL, SUPABASE_ANON_KEY } from './config.js';

// Bound every Supabase call so a stalled upstream can't pin requests for minutes.
const fetchWithTimeout = (url, init) => fetch(url, { ...init, signal: AbortSignal.timeout(10_000) });

// Forward the caller's token so Supabase RLS still applies as a second guard.
export const clientFor = (token) => createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  accessToken: async () => token,
  global: { fetch: fetchWithTimeout },
});

// No user token, so RLS hides every row: all the deep health check needs is an answer.
export const anon = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, { global: { fetch: fetchWithTimeout } });

export async function must(query) {
  const { data, error, status } = await query;
  if (error) {
    // PostgREST already picks the right 4xx (bad input 400, conflict 409, RLS 403, rejected JWT 401).
    // .single() matching no row arrives as 406: really "missing, or someone else's".
    error.status = error.code === 'PGRST116' ? 404 : status >= 400 && status < 500 ? status : 500;
    throw error;
  }
  return data;
}

export const send = (res, query, status = 200) =>
  must(query).then((data) => res.status(status).json(data));

// Supabase silently caps a response at max_rows (default 1000), so page until a short page.
// ponytail: assumes the project's max_rows >= PAGE; lower PAGE if that setting is ever lowered.
const PAGE = 1000;
export async function sendAll(res, query) {
  const rows = [];
  for (;;) {
    // `id` tiebreak keeps page boundaries stable when the sort column has duplicates.
    const page = await must(query().order('id').range(rows.length, rows.length + PAGE - 1));
    rows.push(...page);
    if (page.length < PAGE) return res.json(rows);
  }
}

// Keep only whitelisted columns. `id` and `user_id` are never on a whitelist.
export const pick = (body, cols) =>
  Object.fromEntries(cols.filter((c) => body && c in body).map((c) => [c, body[c]]));

// Every query below is scoped to the token's `sub`; routes never trust a client user_id.
export const list = (req, table) => req.db.from(table).select().eq('user_id', req.userId);
export const updateOwn = (req, table, values) =>
  req.db.from(table).update(values).eq('id', req.params.id).eq('user_id', req.userId).select().single();
export const deleteOwn = (req, table) =>
  req.db.from(table).delete().eq('id', req.params.id).eq('user_id', req.userId);
export const row = (req, cols, body = req.body) => ({ ...pick(body, cols), user_id: req.userId });
