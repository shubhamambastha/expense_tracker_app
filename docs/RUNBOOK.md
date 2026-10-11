# Runbook

What to check, in order, when something breaks in production. One owner: you. No rotation, no escalation tiers. Vendor status pages are the only "upstream."

See also: [BACKEND.md](./BACKEND.md) (API, logs), [DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md) (migrations), [auth0_setup.md](./auth0_setup.md).

## Where things live

| What | Where | Notes |
| --- | --- | --- |
| API | Railway → project → service | **Auto-deploys `main`.** Deployments (rollback), Logs, Metrics (CPU, memory, network) |
| Database | Supabase → `expense-tracker` (`ap-south-1`) | Logs Explorer (~24 h on Free), Reports, Database → Backups. Free plan hibernates idle projects |
| Login | Auth0 tenant → Monitoring → Logs | Failed logins, signups, rate-limit blocks |
| Status pages | status.railway.com · status.supabase.com · status.auth0.com | Check these before debugging your own code |

## Health checks

| URL | 200 means | Watch with |
| --- | --- | --- |
| `GET /health` | Node is running | Railway deploy health check |
| `GET /health/db` | Node is running **and** Supabase answers | External uptime monitor, every 1–5 min |

## Railway log filters

Each request writes one JSON line ([BACKEND.md#logs](./BACKEND.md#logs)). In Railway → Logs:

- `@level:error`: 5xx responses, plus their cause line (`code`, `stack`)
- `@status:401`: token rejections
- `@path:/v1/budgets`: one route. Ids are collapsed to `:id`
- `@user:"auth0|…"`: one person's requests, given the id from a support email (the Delete Account mail includes it)

The `code` on error lines is a Postgres SQLSTATE or a PostgREST/jose code. Search it before guessing.

## Symptom → cause → fix

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `/health` down, or Railway shows a crash loop | Bad deploy, or a missing env var (`config.js` crashes at boot with `Missing env X`) | Railway → Deployments → last good one → **Redeploy** (that's the rollback). Then fix the env var or revert the commit on `main` |
| `/health` OK, `/health/db` 500 | Supabase down or hibernated, or `SUPABASE_URL`/`SUPABASE_ANON_KEY` wrong after a key rotation | Supabase dashboard: project status (Restore if paused); status page; compare Railway env with Supabase → Settings → API Keys |
| Every signed-in user gets "Invalid or expired token" | `AUTH0_DOMAIN`/`AUTH0_CLIENT_ID` on Railway don't match the app build | Compare Railway env with the build's `--dart-define`s / GitHub secrets |
| 500s with jose `ERR_JWKS_*` or `fetch failed` on auth | Auth0 or its JWKS endpoint unreachable | Auth0 status page. Recovers by itself, since JWKS is cached 12 h once fetched |
| 401 with `code: PGRST301` | Supabase rejecting the forwarded Auth0 token | [auth0_setup.md → Fix PGRST301](./auth0_setup.md#fix-pgrst301--no-suitable-key-was-found-to-decode-the-jwt) |
| 400/500 with `42703` or `PGRST204` | **A migration in `sql/` wasn't applied.** The code writes a column the DB lacks | Apply the missing file from [DATABASE_SCHEMA.md → apply order](./DATABASE_SCHEMA.md#migration-apply-order) |
| 400 with `42P10` on `/v1/budgets` | `20261011_perf_indexes.sql` missing | Apply it |
| 403 / `42501` | RLS denied: a write for another user's row, or a token with no `sub` | Expected for attacks. If a real user hits it, check the token claims |
| Slow responses | Railway CPU at its limit; Supabase cold start after hibernation; one heavy user's full-list fetch | Railway Metrics; the `ms` field by `@path`; Supabase → Reports → Query performance |
| Data wrong after a migration | No down-migrations exist | Write the reverse SQL by hand. Before any risky migration, take a dump first (`supabase db dump` / `pg_dump`). Check Database → Backups for what your plan keeps |
| A secret leaked | — | Create a new key at the source (Supabase API Keys / Auth0), set it on Railway, redeploy, **then** delete the old one |

## Business metrics

Signups and logins: Auth0 dashboard → Activity. Product usage (Supabase SQL editor):

```sql
-- Daily active users (anyone who added a transaction) and transactions added, last 30 days
select inserted_at::date as day, count(distinct user_id) as active_users, count(*) as transactions_added
from public.transactions
where inserted_at > now() - interval '30 days'
group by 1 order by 1 desc;

-- Funnel snapshot
select (select count(*) from public.user_settings)                         as users,
       (select count(distinct user_id) from public.transactions)            as users_with_transactions,
       (select count(distinct user_id) from public.category_budgets)        as users_with_budgets,
       (select count(distinct user_id) from public.transactions
         where inserted_at > now() - interval '7 days')                     as weekly_active;
```
