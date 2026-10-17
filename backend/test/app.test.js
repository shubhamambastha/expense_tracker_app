import { test, before, after, beforeEach, mock } from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { generateKeyPair, exportJWK, SignJWT } from 'jose';

Object.assign(process.env, {
  SUPABASE_URL: 'http://supabase.test',
  SUPABASE_ANON_KEY: 'anon',
  SUPABASE_SERVICE_ROLE_KEY: 'service',
});

// Fake Supabase (JWKS, PostgREST, auth admin) by intercepting the global fetch that jose and
// supabase-js both call. Requests to the API under test pass through.
const key = await generateKeyPair('ES256');
const jwk = { ...(await exportJWK(key.publicKey)), kid: 'k1', alg: 'ES256' };
let calls = [];
let respond = null; // (call) => Response | undefined, per test
let jwksDown = false;
const realFetch = globalThis.fetch;
globalThis.fetch = async (input, init = {}) => {
  const url = new URL(typeof input === 'string' ? input : input.url);
  if (url.host !== 'supabase.test') return realFetch(input, init);
  if (url.pathname === '/auth/v1/.well-known/jwks.json') {
    if (jwksDown) throw new TypeError('fetch failed');
    return Response.json({ keys: [jwk] });
  }
  const headers = new Headers(init.headers);
  const call = {
    method: init.method ?? 'GET',
    table: url.pathname.replace('/rest/v1/', ''),
    params: Object.fromEntries(url.searchParams),
    auth: headers.get('authorization'),
    prefer: headers.get('prefer') ?? '',
    body: init.body ? JSON.parse(init.body) : undefined,
  };
  calls.push(call);
  const custom = respond?.(call);
  if (custom) return custom;
  const single = (headers.get('accept') ?? '').includes('pgrst.object');
  return Response.json(single ? { id: 1 } : [{ id: 1 }]);
};
const pgError = (status, code, message = `pg ${code}`) => Response.json({ code, message }, { status });

const { app } = await import('../src/app.js');
mock.method(console, 'info', () => {}); // request log lines; asserted on below

const SUB = '5f0c6a8e-1b2d-4c3e-9f40-a1b2c3d4e5f6';
const sign = ({ privateKey = key.privateKey, iss = 'http://supabase.test/auth/v1', aud = 'authenticated', exp = '5m' } = {}) =>
  new SignJWT({ role: 'authenticated' }).setProtectedHeader({ alg: 'ES256', kid: 'k1' })
    .setIssuer(iss).setAudience(aud).setSubject(SUB).setExpirationTime(exp).sign(privateKey);

let server, base, token;
before(async () => {
  token = await sign();
  await new Promise((resolve) => {
    server = app.listen(0, () => {
      base = `http://127.0.0.1:${server.address().port}`;
      resolve();
    });
  });
});
after(() => server.close());
beforeEach(() => { calls = []; respond = null; });

const call = (method, path, body, auth = token) => realFetch(base + path, {
  method,
  headers: { Authorization: `Bearer ${auth}`, 'content-type': 'application/json' },
  body: body === undefined ? undefined : typeof body === 'string' ? body : JSON.stringify(body),
});

test('health is public', async () => {
  const res = await fetch(`${base}/health`);
  assert.equal(res.status, 200);
});

test('CORS preflight passes without a token, and responses carry the allow-origin header', async () => {
  const pre = await realFetch(`${base}/v1/transactions`, {
    method: 'OPTIONS',
    headers: { Origin: 'http://localhost:5000', 'Access-Control-Request-Method': 'PATCH', 'Access-Control-Request-Headers': 'authorization,content-type' },
  });
  assert.equal(pre.status, 204);
  assert.equal(pre.headers.get('access-control-allow-origin'), '*');
  assert.match(pre.headers.get('access-control-allow-methods'), /PATCH/);
  assert.match(pre.headers.get('access-control-allow-headers'), /Authorization/);
  // Not an authed /v1 call: that would warm jose's JWKS cache and defeat the JWKS-outage test below.
  const res = await realFetch(`${base}/health`, { headers: { Origin: 'http://localhost:5000' } });
  assert.equal(res.headers.get('access-control-allow-origin'), '*');
});

test('/health/db proves Supabase answers, and 500s when it does not', async (t) => {
  t.mock.method(console, 'error', () => {});
  const ok = await fetch(`${base}/health/db`);
  assert.equal(ok.status, 200);
  assert.equal(calls[0].table, 'user_settings');
  respond = () => { throw new TypeError('fetch failed'); };
  const down = await fetch(`${base}/health/db`);
  assert.equal(down.status, 500);
});

test('every response carries the security headers, including errors', async () => {
  for (const path of ['/health', '/nope', '/v1/transactions']) {
    const res = await fetch(base + path);
    assert.match(res.headers.get('strict-transport-security'), /max-age=\d+/, path);
    assert.equal(res.headers.get('x-content-type-options'), 'nosniff', path);
    assert.match(res.headers.get('content-security-policy'), /default-src 'none'/, path);
  }
});

test('every data route rejects requests without a valid token', async () => {
  for (const [method, path] of [
    ['GET', '/v1/transactions'],
    ['POST', '/v1/accounts'],
    ['PATCH', '/v1/settings'],
    ['DELETE', '/v1/data'],
    ['DELETE', '/v1/account'],
  ]) {
    const missing = await fetch(base + path, { method });
    assert.equal(missing.status, 401, `${method} ${path} without token`);
    const forged = await fetch(base + path, { method, headers: { Authorization: 'Bearer not.a.jwt' } });
    assert.equal(forged.status, 401, `${method} ${path} with forged token`);
  }
});

test('unknown routes return JSON 404', async () => {
  const res = await fetch(`${base}/nope`);
  assert.equal(res.status, 404);
  assert.deepEqual(await res.json(), { error: 'Not found' });
});

// Must run before any token is verified: jose caches the JWKS once fetched.
test('a Supabase JWKS outage is a logged 500, not a 401 blaming the caller', async (t) => {
  t.mock.method(console, 'error', () => {});
  jwksDown = true;
  try {
    const res = await call('GET', '/v1/transactions');
    assert.equal(res.status, 500);
    assert.equal(console.error.mock.callCount(), 1);
  } finally {
    jwksDown = false;
  }
  assert.equal(calls.length, 0);
});

test('well-formed JWTs failing verification are 401 and never reach the database', async () => {
  const other = await generateKeyPair('ES256');
  const cases = {
    'signed by an unknown key': await sign({ privateKey: other.privateKey }),
    'wrong issuer': await sign({ iss: 'https://evil.test/auth/v1' }),
    'wrong audience': await sign({ aud: 'anon' }),
    expired: await sign({ exp: Math.floor(Date.now() / 1000) - 60 }),
  };
  for (const [name, bad] of Object.entries(cases)) {
    const res = await call('GET', '/v1/transactions', undefined, bad);
    assert.equal(res.status, 401, name);
    assert.deepEqual(await res.json(), { error: 'Invalid or expired token' }, name);
  }
  assert.equal(calls.length, 0);
});

test('list routes scope to the token sub and forward the caller token for RLS', async () => {
  const res = await call('GET', '/v1/transactions');
  assert.equal(res.status, 200);
  assert.deepEqual(await res.json(), [{ id: 1 }]);
  const [q] = calls;
  assert.equal(q.table, 'transactions');
  assert.equal(q.params.user_id, `eq.${SUB}`);
  assert.equal(q.params.order, 'date.desc,id.asc');
  assert.equal(q.auth, `Bearer ${token}`);
});

test('writes force user_id from the token and drop id / unknown columns', async () => {
  const evil = { id: 99, user_id: 'someone-else', amount: 5, kind: 'expense', hacked: true };
  const created = await call('POST', '/v1/transactions', evil);
  assert.equal(created.status, 201);
  assert.deepEqual(calls[0].body, { amount: 5, kind: 'expense', user_id: SUB });

  const patched = await call('PATCH', '/v1/accounts/7', { is_archived: true, user_id: 'someone-else', id: 8 });
  assert.equal(patched.status, 200);
  assert.deepEqual(calls[1].body, { is_archived: true });
  assert.equal(calls[1].params.id, 'eq.7');
  assert.equal(calls[1].params.user_id, `eq.${SUB}`);

  const account = await call('POST', '/v1/accounts', { name: 'Cash', type: 'cash', user_id: 'someone-else', id: 3, hacked: 1 });
  assert.equal(account.status, 201);
  assert.deepEqual(calls[2].body, { name: 'Cash', type: 'cash', user_id: SUB });
});

test('non-numeric ids 404 without touching the database', async () => {
  for (const path of ['/v1/accounts/abc', '/v1/transactions/1.5', '/v1/budgets/1;drop', '/v1/accounts/1234567890123456789']) {
    const res = await call('PATCH', path, { is_archived: true });
    assert.equal(res.status, 404, path);
  }
  assert.equal((await call('DELETE', '/v1/categories/income/abc')).status, 404);
  assert.equal(calls.length, 0);
});

test('PostgREST errors map to HTTP statuses; unmapped ones hide details behind a 500', async (t) => {
  t.mock.method(console, 'error', () => {});
  t.mock.method(console, 'warn', () => {});
  for (const [pgStatus, code, expected] of [
    [406, 'PGRST116', 404], // someone else's / missing row
    [409, '23505', 409],
    [409, '23503', 409],
    [403, '42501', 403],
    [400, '22P02', 400],
    [400, '23502', 400],
    [400, '23514', 400],
    [400, '22007', 400], // any PostgREST 4xx passes through (bad date)
    [401, 'PGRST301', 401], // Supabase rejected the forwarded JWT
    [500, 'XX000', 500],
  ]) {
    respond = () => pgError(pgStatus, code, 'secret detail');
    const res = await call('PATCH', '/v1/transactions/1', { amount: 1 });
    assert.equal(res.status, expected, code);
    const body = await res.json();
    assert.equal(body.code, code);
    assert.ok(!body.error.includes('secret detail'), `${code} leaks the raw Postgres message`);
    if (expected >= 500) assert.equal(body.error, 'Internal server error', code);
  }
  respond = () => { throw new TypeError('fetch failed'); }; // Supabase unreachable
  const down = await call('PATCH', '/v1/transactions/1', { amount: 1 });
  assert.equal(down.status, 500);
  assert.equal((await down.json()).error, 'Internal server error');
});

test('list routes page past Supabase max_rows instead of silently truncating', async () => {
  respond = (c) => {
    const offset = Number(c.params.offset ?? 0);
    const size = offset === 0 ? 1000 : 1;
    return Response.json(Array.from({ length: size }, (_, i) => ({ id: offset + i + 1 })));
  };
  const res = await call('GET', '/v1/transactions');
  const rows = await res.json();
  assert.equal(rows.length, 1001);
  assert.deepEqual(calls.map((c) => [c.params.offset ?? '0', c.params.limit]), [['0', '1000'], ['1000', '1000']]);
});

test('every list and per-id delete route is scoped to the caller', async () => {
  for (const [path, table, order] of [
    ['/v1/recurring-events', 'recurring_events', 'occurrence_date.desc,id.asc'],
    ['/v1/budgets', 'category_budgets', 'category_name.asc,id.asc'],
    ['/v1/categories/expense', 'expense_categories', 'sort_order.asc,name.asc,id.asc'],
    ['/v1/categories/income', 'income_categories', 'sort_order.asc,name.asc,id.asc'],
  ]) {
    calls = [];
    assert.equal((await call('GET', path)).status, 200, path);
    assert.deepEqual([calls[0].table, calls[0].params.user_id, calls[0].params.order], [table, `eq.${SUB}`, order], path);
  }
  for (const [path, table] of [
    ['/v1/transactions/5', 'transactions'],
    ['/v1/recurring-events/5', 'recurring_events'],
    ['/v1/accounts/5', 'accounts'],
    ['/v1/budgets/5', 'category_budgets'],
    ['/v1/categories/income/5', 'income_categories'],
  ]) {
    calls = [];
    assert.equal((await call('DELETE', path)).status, 204, path);
    assert.deepEqual([calls[0].method, calls[0].table, calls[0].params.id, calls[0].params.user_id], ['DELETE', table, 'eq.5', `eq.${SUB}`], path);
  }
});

test('malformed and oversized JSON bodies are rejected with 4xx', async () => {
  assert.equal((await call('POST', '/v1/transactions', '{bad')).status, 400);
  assert.equal((await call('POST', '/v1/transactions', { note: 'x'.repeat(1.1e6) })).status, 413);
  assert.equal(calls.length, 0);
});

test('large list responses are gzipped for clients that ask', async () => {
  respond = () => Response.json(Array.from({ length: 50 }, (_, id) => ({ id, note: 'x'.repeat(40) })));
  const res = await realFetch(`${base}/v1/transactions`, {
    headers: { Authorization: `Bearer ${token}`, 'Accept-Encoding': 'gzip' },
  });
  assert.equal(res.status, 200);
  assert.equal(res.headers.get('content-encoding'), 'gzip');
  assert.equal((await res.json()).length, 50);
});

test('each request logs one JSON line, never the token; health checks are skipped', async () => {
  console.info.mock.resetCalls();
  await call('DELETE', '/v1/transactions/42');
  await fetch(`${base}/health`);
  await fetch(`${base}/v1/accounts?includeArchived=true`); // no token: 401
  await new Promise(setImmediate);
  const lines = console.info.mock.calls.map((c) => c.arguments[0]);
  assert.equal(lines.length, 2);
  assert.ok(lines.every((line) => !line.includes(token)), 'bearer token in the log');
  const [deleted, rejected] = lines.map((line) => JSON.parse(line));
  assert.equal(typeof deleted.ms, 'number');
  assert.deepEqual({ ...deleted, ms: 0 }, {
    level: 'info', message: 'DELETE /v1/transactions/:id 204', method: 'DELETE',
    path: '/v1/transactions/:id', status: 204, ms: 0, user: SUB,
  });
  assert.equal(rejected.path, '/v1/accounts');
  assert.equal(rejected.level, 'warn');
  assert.equal(rejected.user, undefined);
});

test('accounts hide archived rows unless includeArchived=true', async () => {
  await call('GET', '/v1/accounts');
  await call('GET', '/v1/accounts?includeArchived=true');
  assert.equal(calls[0].params.is_archived, 'eq.false');
  assert.equal(calls[1].params.is_archived, undefined);
  assert.equal(calls[1].params.user_id, `eq.${SUB}`);
});

test('recurring events and budgets upsert on their natural keys', async () => {
  const ev = await call('POST', '/v1/recurring-events', { transaction_id: 3, occurrence_date: '2026-01-01', event_type: 'paid', id: 9 });
  assert.equal(ev.status, 201);
  assert.equal(calls[0].params.on_conflict, 'user_id,transaction_id,occurrence_date,event_type');
  assert.match(calls[0].prefer, /resolution=merge-duplicates/);
  assert.equal(calls[0].body.id, undefined);

  const budget = await call('POST', '/v1/budgets', { category_name: 'Food', monthly_limit: 100 });
  assert.equal(budget.status, 200);
  assert.equal(calls[1].params.on_conflict, 'user_id,category_name');
  assert.deepEqual(calls[1].body, { category_name: 'Food', monthly_limit: 100, user_id: SUB });
});

test('categories: bulk seed returns an array, single insert an object, defaults are undeletable', async () => {
  const seeded = await call('POST', '/v1/categories/income', [{ name: 'Salary', is_default: true, user_id: 'x' }, { name: 'Gift' }]);
  assert.equal(seeded.status, 201);
  assert.deepEqual(await seeded.json(), [{ id: 1 }]);
  assert.equal(calls[0].table, 'income_categories');
  assert.deepEqual(calls[0].body, [{ name: 'Salary', is_default: true, user_id: SUB }, { name: 'Gift', user_id: SUB }]);

  const one = await call('POST', '/v1/categories/expense', { name: 'Pets', icon: 'paw', sort_order: 9, is_default: false });
  assert.equal(one.status, 201);
  assert.deepEqual(await one.json(), { id: 1 });

  const del = await call('DELETE', '/v1/categories/expense/3');
  assert.equal(del.status, 204);
  assert.equal(calls[2].params.is_default, 'eq.false');
  assert.equal(calls[2].params.user_id, `eq.${SUB}`);
});

test('settings: GET with no row is null; PATCH sends only the columns given', async () => {
  respond = (c) => (c.method === 'GET' ? Response.json([]) : undefined);
  const got = await call('GET', '/v1/settings');
  assert.equal(got.status, 200);
  assert.equal(await got.json(), null);

  // A currency-only update must not send `preferences`, or the stored blob would be wiped.
  await call('PATCH', '/v1/settings', { default_currency_code: 'INR', user_id: 'x' });
  assert.deepEqual(calls[1].body, { default_currency_code: 'INR', user_id: SUB });
  assert.match(calls[1].prefer, /resolution=merge-duplicates/);
});

test('DELETE /data wipes every user table in FK order and stops on the first failure', async () => {
  const res = await call('DELETE', '/v1/data');
  assert.equal(res.status, 204);
  assert.deepEqual(calls.map((c) => c.table), [
    'recurring_events', 'transactions', 'accounts',
    'category_budgets', 'expense_categories', 'income_categories',
  ]);
  assert.ok(calls.every((c) => c.method === 'DELETE' && c.params.user_id === `eq.${SUB}`));

  calls = [];
  respond = (c) => (c.table === 'transactions' ? pgError(409, '23503') : undefined);
  const failed = await call('DELETE', '/v1/data');
  assert.equal(failed.status, 409);
  assert.deepEqual(calls.map((c) => c.table), ['recurring_events', 'transactions']);
});

const noSettingsLeft = (c) => (c.method === 'GET' ? Response.json([]) : undefined);
const isAdmin = (c) => c.table.startsWith('/auth/');

test('DELETE /account checks the service key, wipes every user table, then deletes the auth user', async (t) => {
  t.mock.method(console, 'error', () => {});
  respond = noSettingsLeft;
  const res = await call('DELETE', '/v1/account');
  assert.equal(res.status, 204);
  const [preflight, ...rest] = calls;
  const [check, user] = rest.slice(-2);
  const rows = rest.slice(0, -2);
  assert.deepEqual([preflight.method, preflight.table, preflight.auth], ['GET', `/auth/v1/admin/users/${SUB}`, 'Bearer service']);
  assert.deepEqual(rows.map((c) => c.table), [
    'recurring_events', 'transactions', 'accounts', 'category_budgets',
    'expense_categories', 'income_categories', 'counterparties', 'user_settings',
  ]);
  assert.ok(rows.every((c) => c.method === 'DELETE' && c.params.user_id === `eq.${SUB}` && c.auth === `Bearer ${token}`));
  assert.deepEqual([check.method, check.table, check.params.user_id, check.auth], ['GET', 'user_settings', `eq.${SUB}`, `Bearer ${token}`]);
  assert.deepEqual([user.method, user.table, user.auth], ['DELETE', `/auth/v1/admin/users/${SUB}`, 'Bearer service']);

  // A failed wipe never deletes the login, so the user can retry.
  calls = [];
  respond = (c) => (c.table === 'accounts' ? pgError(500, 'XX000') : noSettingsLeft(c));
  const failed = await call('DELETE', '/v1/account');
  assert.equal(failed.status, 500);
  assert.ok(!calls.some((c) => isAdmin(c) && c.method === 'DELETE'));
});

test('DELETE /account touches no data when the service key does not work', async (t) => {
  t.mock.method(console, 'error', () => {});
  respond = (c) => (isAdmin(c) ? Response.json({ code: 'not_admin', msg: 'User not allowed' }, { status: 403 }) : noSettingsLeft(c));
  const res = await call('DELETE', '/v1/account');
  assert.equal(res.status, 500);
  assert.deepEqual(await res.json(), { error: 'Internal server error' });
  assert.deepEqual(calls.map((c) => c.method), ['GET']); // only the preflight
});

test('DELETE /account keeps the login when RLS silently left user_settings behind', async (t) => {
  t.mock.method(console, 'error', () => {});
  respond = (c) => (c.method === 'GET' && !isAdmin(c) ? Response.json([{ user_id: SUB }]) : undefined);
  const res = await call('DELETE', '/v1/account');
  assert.equal(res.status, 500);
  assert.ok(!calls.some((c) => isAdmin(c) && c.method === 'DELETE'));
});

test('DELETE /account: a refused auth delete is an opaque 500; an already-deleted user is a 204 (retry)', async (t) => {
  t.mock.method(console, 'error', () => {});
  respond = (c) => (isAdmin(c) && c.method === 'DELETE'
    ? Response.json({ code: 'unexpected_failure', msg: 'boom' }, { status: 500 })
    : noSettingsLeft(c));
  const refused = await call('DELETE', '/v1/account');
  assert.equal(refused.status, 500);
  assert.deepEqual(await refused.json(), { error: 'Internal server error' });
  assert.equal(calls.length, 11); // preflight, 8 deletes, the leftover check, then the auth user

  calls = [];
  respond = (c) => (isAdmin(c)
    ? Response.json({ code: 'user_not_found', msg: 'User not found' }, { status: 404 })
    : noSettingsLeft(c));
  assert.equal((await call('DELETE', '/v1/account')).status, 204);
});

test('anonymous Supabase users are rejected', async () => {
  const anonUser = await new SignJWT({ role: 'authenticated', is_anonymous: true }).setProtectedHeader({ alg: 'ES256', kid: 'k1' })
    .setIssuer('http://supabase.test/auth/v1').setAudience('authenticated').setSubject(SUB).setExpirationTime('5m').sign(key.privateKey);
  assert.equal((await call('GET', '/v1/transactions', undefined, anonUser)).status, 401);
  assert.equal(calls.length, 0);
});

test('the server refuses to boot without required env', () => {
  for (const [env, missing] of [
    [{}, 'SUPABASE_URL'],
    [{ SUPABASE_URL: 'http://x', SUPABASE_ANON_KEY: 'a' }, 'SUPABASE_SERVICE_ROLE_KEY'],
  ]) {
    const { status, stderr } = spawnSync(process.execPath, [
      '--input-type=module', '-e', `await import(${JSON.stringify(new URL('../src/app.js', import.meta.url).href)})`,
    ], { env: { PATH: process.env.PATH, ...env }, encoding: 'utf8' });
    assert.notEqual(status, 0);
    assert.match(stderr, new RegExp(`Missing env ${missing}`));
  }
});

test('HS256 tokens (no matching key in the JWKS) and tokens without a sub are 401 and never reach the database', async () => {
  const hs256 = await new SignJWT({ role: 'authenticated' }).setProtectedHeader({ alg: 'HS256' })
    .setIssuer('http://supabase.test/auth/v1').setAudience('authenticated').setSubject(SUB).setExpirationTime('5m')
    .sign(new TextEncoder().encode('legacy-jwt-secret-at-least-32-bytes!'));
  const noSub = await new SignJWT({ role: 'authenticated' }).setProtectedHeader({ alg: 'ES256', kid: 'k1' })
    .setIssuer('http://supabase.test/auth/v1').setAudience('authenticated').setExpirationTime('5m').sign(key.privateKey);
  for (const [name, bad] of Object.entries({ hs256, noSub })) {
    const res = await call('DELETE', '/v1/account', undefined, bad);
    assert.equal(res.status, 401, name);
  }
  assert.equal(calls.length, 0);
});
