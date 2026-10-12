# Runbook

What to check, in order, when something breaks in production. One owner: you. No rotation, no escalation tiers. Vendor status pages are the only "upstream."

See also: [BACKEND.md](./BACKEND.md) (API, logs), [DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md) (migrations), [supabase_setup.md](./supabase_setup.md) (auth providers).

## Where things live

| What | Where | Notes |
| --- | --- | --- |
| API | Railway → project → service | **Auto-deploys `main`.** Deployments (rollback), Logs, Metrics (CPU, memory, network) |
| Database | Supabase → `expense-tracker` (`ap-south-1`) | Logs Explorer (~24 h on Free), Reports, Database → Backups. Free plan hibernates idle projects |
| Login | Supabase → Authentication → Users, and Logs → Auth | Failed logins, signups, rate-limit blocks, email send failures |
| Status pages | status.railway.com · status.supabase.com | Check these before debugging your own code |

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
- `@user:"<uuid>"`: one person's requests, given their user id (Supabase → Authentication → Users)

The `code` on error lines is a Postgres SQLSTATE or a PostgREST/jose code. Search it before guessing.

## Symptom → cause → fix

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `/health` down, or Railway shows a crash loop | Bad deploy, or a missing env var (`config.js` crashes at boot with `Missing env X`) | Railway → Deployments → last good one → **Redeploy** (that's the rollback). Then fix the env var or revert the commit on `main` |
| `/health` OK, `/health/db` 500 | Supabase down or hibernated, or `SUPABASE_URL`/`SUPABASE_ANON_KEY` wrong after a key rotation | Supabase dashboard: project status (Restore if paused); status page; compare Railway env with Supabase → Settings → API Keys |
| Every signed-in user gets "Invalid or expired token" | `SUPABASE_URL` on Railway isn't the project the app build signs in to, or the project is still on legacy HS256 JWT keys | Compare Railway env with the build's `--dart-define`s / GitHub secrets; Supabase → Settings → JWT Keys must use asymmetric keys |
| 500s with jose `ERR_JWKS_*` or `fetch failed` on auth | Supabase Auth's JWKS endpoint unreachable | Supabase status page. Recovers by itself, since JWKS is cached 12 h once fetched |
| 401 with `code: PGRST301` | Supabase rejecting the forwarded token (key rotated, or `SUPABASE_URL` points at another project) | Compare Railway env with the app build; Supabase → Settings → JWT Keys |
| Sign-up never gets the code email | Built-in email sender rate limit, or SMTP misconfigured | Supabase → Logs → Auth; set up custom SMTP ([supabase_setup.md](./supabase_setup.md#2-email--password)) |
| `DELETE /v1/account` 500, log `user_settings survived account deletion` | `20261012_user_settings_delete_policy.sql` not applied (RLS turns the delete into a no-op) | Apply it; the user's login was kept, so they can retry |
| `DELETE /v1/account` 500, log `auth user delete failed` | `SUPABASE_SERVICE_ROLE_KEY` missing/rotated on Railway (rows are deleted, the login isn't) | Fix the env var; the user can retry (an already-deleted user returns 204), or delete them in Authentication → Users |
| 400/500 with `42703` or `PGRST204` | **A migration in `sql/` wasn't applied.** The code writes a column the DB lacks | Apply the missing file from [DATABASE_SCHEMA.md → apply order](./DATABASE_SCHEMA.md#migration-apply-order) |
| 400 with `42P10` on `/v1/budgets` | `20261011_perf_indexes.sql` missing | Apply it |
| 403 / `42501` | RLS denied: a write for another user's row, or a token with no `sub` | Expected for attacks. If a real user hits it, check the token claims |
| Slow responses | Railway CPU at its limit; Supabase cold start after hibernation; one heavy user's full-list fetch | Railway Metrics; the `ms` field by `@path`; Supabase → Reports → Query performance |
| Data wrong after a migration | No down-migrations exist | Write the reverse SQL by hand. Before any risky migration, take a dump first (`supabase db dump` / `pg_dump`). Check Database → Backups for what your plan keeps |
| Revoked a Supabase JWT signing key (compromise) | The API caches JWKS for 12 h, so the old key keeps verifying | Redeploy/restart the backend on Railway right after revoking |
| A secret leaked | — | Create a new key at the source (Supabase API Keys / Google Cloud credentials), set it on Railway, redeploy, **then** delete the old one |

## Business metrics

Signups and logins: Supabase → Authentication → Users (and `auth.users.last_sign_in_at`). Product usage (Supabase SQL editor):

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
