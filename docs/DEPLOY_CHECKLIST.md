# Deploy Checklist

Pre-release gate for the app + `backend/` API (Railway) + Supabase. One section per area. Every verdict cites the code or a live probe.

Legend: `[x]` pass · `[ ]` open · `n/a` doesn't apply to this stack

> **2026-10-12:** login moved from Auth0 to Supabase Auth. Auth items below are updated for that; Auth0 mentions elsewhere describe the stack as audited on 2026-10-11. Re-run this checklist before release.

---

## 1. Security

**Date:** 2026-10-11 · **Checked by:** Claude (Opus 5.5) for Shubham Ambastha · **Scope:** `main` @ `d20c9d5`, live API `expensetrackerapp-production-0d6a.up.railway.app`, Supabase project `expense-tracker`

### Blockers: fix before release

| # | Item | Action (owner: you, dashboard work) |
| --- | --- | --- |
| B1 | **The Supabase publishable key is in public git history and still live.** Commits `2ed6530`…`aa935f7` hardcoded the project URL and key. A probe on 2026-10-11 got HTTP 200 from PostgREST with it. RLS still isolates users (anon gets `[]`), and since the Supabase Auth switch the app ships the publishable key anyway, so any signed-in user can reach PostgREST directly (RLS is the boundary). | Supabase → Settings → API Keys: create a new publishable key, set it as `SUPABASE_ANON_KEY` on Railway **and** as the app's `SUPABASE_PUBLISHABLE_KEY` (config + CI secret), ship that build, and only then **delete** the old `sb_publishable_M1CW…` key (deleting it first breaks login in every build that carries it). |
| B2 | **The Android release build is signed with the debug keystore unless `android/key.properties` exists** ([build.gradle.kts](../android/app/build.gradle.kts)). Gradle now reads the upload key from that gitignored file and logs a warning when it falls back to debug keys. Play rejects debug-signed builds, and the debug key isn't secret. | Create the upload keystore and `android/key.properties`, enable Play App Signing, and add the upload and app-signing SHA-1s to the Google Android OAuth client. |
| B3 | **Privacy Policy is a stub** ([about_page.dart:37](../lib/screens/settings/sections/about_page.dart)). Both stores require a privacy policy for apps that collect financial data. Delete Account is self-service since 2026-10-12 (`DELETE /v1/account`), but Apple 5.1.1(v) also requires revoking Sign in with Apple tokens on deletion, which isn't done yet (P1 in TODOS). | Publish a policy and link it. Implement the Apple token revoke before App Store submission. |
| B4 | **Supabase Auth cutover order (2026-10-12).** Railway auto-deploys `main`, and the new backend refuses to boot without `SUPABASE_SERVICE_ROLE_KEY`, then rejects every Auth0 token. | **Before merging:** apply `sql/20261012_user_settings_delete_policy.sql`; move the project to asymmetric JWT keys and check `<SUPABASE_URL>/auth/v1/.well-known/jwks.json` lists ES256/RS256 keys; set `SUPABASE_SERVICE_ROLE_KEY` on Railway. **Merge**, confirm `/health` and `/health/db`. **Then:** ship the new app build and tell testers to update (old builds get 401s), turn off the Third-Party Auth0 integration, remove `AUTH0_*` from Railway, take a backup and run `sql/20261012_drop_auth0_rows.sql`. |

### Environment & secrets

- [ ] **No hardcoded secrets in code.** HEAD is clean (grep of tree + `git log -p`: no service-role keys, client secrets, private keys or JWTs). History is not clean, see **B1**. The Auth0 domain and native client ID in docs/config are public identifiers by design.
- [x] **Environment variables documented.** [`backend/.env.example`](../backend/.env.example), [`config.dev.json.example`](../config.dev.json.example), [BACKEND.md#deploy](./BACKEND.md#deploy), CI secrets in [supabase_setup.md](./supabase_setup.md). [`config.js`](../backend/src/config.js) crashes on boot if any are missing (tested).
- [x] **Secrets manager configured.** Railway env vars hold the backend secrets, GitHub Actions secrets hold CI's. `.env` and `config.*.json` are gitignored. GitHub secret scanning and push protection are **on**. A dedicated vault isn't warranted at this size.
- [ ] **API keys rotated.** See **B1**.
- [ ] **Database credentials secured.** The backend never holds the Postgres password. Since 2026-10-12 it does hold the **service-role key**, used only by `DELETE /v1/account` to remove the auth user; every data query still uses the publishable key plus the caller's own token ([db.js](../backend/src/db.js)). A leaked backend env *can* now bypass RLS. → Keep Railway membership to you, MFA on, and rotate the key if the env ever leaks.

### Authentication & authorization

- [ ] **Password hashing.** Supabase Auth stores the hashes (bcrypt); we never see passwords. → Turn on **Leaked password protection** (Pro plan) and keep the 8-character minimum in Authentication → Providers → Email. Set up custom SMTP so confirmation and reset codes actually arrive.
- [x] **Session management.** The Supabase session (incl. refresh token) is stored in the Keychain on iOS and Keystore-backed storage on Android (`flutter_secure_storage`). The SDK refreshes the 1 h access token ahead of expiry, a 401 gets one retry with a forced refresh, and logout removes the stored session ([api_service.dart](../lib/services/api_service.dart), [auth_service.dart](../lib/services/auth_service.dart)).
- [ ] **MFA available for admins.** The app has no admin role. The real admins are the Supabase, Railway, GitHub and Google Cloud / Apple Developer accounts. → Confirm MFA is on for all of them (I can't check this from here).
- [x] **Authorization checks in place.** Every `/v1` route runs `auth` ([routes/index.js](../backend/src/routes/index.js)). `jwtVerify` pins ES256/RS256, the Supabase issuer, audience `authenticated` and `sub`. `user_id` always comes from the token, and `id`/`user_id` are never on a whitelist. **Live DB:** RLS is on for all 8 public tables and every policy requires `requesting_user_id() IS NOT NULL`. There are no SECURITY DEFINER functions and no legacy `expenses` table. **Live API:** missing, garbage and `alg=none` tokens all get 401. Known low gap: cross-user FK references (TODOS P2).
- n/a **RBAC.** Single-role app; isolation is per user.

### Data protection

- [x] **HTTPS/TLS enabled.** Railway serves TLS 1.3, and HTTP gets a 301 to HTTPS. **Fixed:** release builds now refuse a non-`https://` `API_BASE_URL`, because `dart:io` ignores iOS ATS and Android cleartext rules. Cleartext is allowed only in the Android *debug* manifest.
- [x] **Sensitive data encrypted.** Supabase data is encrypted at rest and tokens sit in the OS keystores. Guest-mode data is plain SharedPreferences/UserDefaults, protected only by the OS sandbox and device encryption. That's accepted, since it never leaves the device.
- [ ] **Backups encrypted.** Supabase manages the backups and encrypts them at rest. → Check your plan's backup retention / PITR in the dashboard.
- [x] **Data transmission encrypted.** App→API, API→Supabase and API→Auth0 JWKS all use HTTPS.
- [ ] **PII handling compliant.** Export (CSV, emailed; needs `RESEND_API_KEY` + `EXPORT_FROM_EMAIL` on Railway and a sender domain verified in Resend), Reset and Delete Account are all self-service. The privacy policy is still a stub, see **B3**.

### API security

- [x] **Input validation on all endpoints.** Per-table column whitelists, a bigint check on `:id`, a 1 MB body cap with strict JSON, and DB types/constraints behind them. There's no per-field schema in the API, so bad types surface as a PostgREST 400. Fine for now.
- [x] **SQL injection prevention.** No raw SQL anywhere. supabase-js parameterises PostgREST calls, `:id` is regex-checked, and the only query param is compared to the literal `'true'`.
- [x] **XSS prevention (CSP).** This is a JSON API and the Flutter client renders no HTML. **Added** `Content-Security-Policy: default-src 'none'` as hardening.
- n/a **CSRF protection.** Auth is a bearer header with no cookies, so there's no ambient credential to forge.
- [ ] **Rate limiting configured.** There's none ([BACKEND.md trade-offs](./BACKEND.md#trade-offs--what-to-revisit)). Auth0 throttles logins, but an authenticated user can hammer `GET /transactions`, which pages through every row. → Add `express-rate-limit` keyed on `req.userId` before a public launch.
- [x] **Dependency vulnerabilities scanned.** `npm audit` (prod + dev) found 0. `flutter pub get` reports no advisories.

### Infrastructure

- [x] **Security headers configured.** **Fixed:** HSTS, `nosniff` and CSP on every response, errors included (tested). `x-powered-by` was already off. → **The live API won't send them until the next deploy.**
- n/a **Firewall rules.** Railway is a PaaS and exposes only HTTPS. → Optional: Supabase → Database → Network Restrictions. The backend never opens a direct Postgres connection, so 5432/6543 can be locked down.
- n/a **SSH hardened.** There are no servers or SSH.
- [x] **Default credentials changed.** None exist. `.env.example` has placeholders only.
- [ ] **Database access restricted.** RLS is on and anon gets `[]` (live probe). Direct PostgREST stays reachable until **B1** is done. Low: `accounts.user_id` is nullable and its insert policy allows `NULL`, so orphan rows are possible via direct PostgREST. `anon`/`authenticated` also keep Supabase's default `TRUNCATE`/`TRIGGER`/`REFERENCES` grants, which PostgREST can't reach. Fold both into the FK-ownership migration in TODOS.

### Security testing

- [ ] **SAST performed.** Done manually: all of `backend/src` was read, and `flutter analyze` is clean. No automated tool ran. → Turn on GitHub **CodeQL default setup**, which is free for public repos.
- [x] **DAST performed (light).** Production probes: no-token, forged and `alg=none` → 401; unknown paths → JSON 404; a 2 MB body → 413; HTTP → 301; TLS 1.3. This was not a full scanner run (ZAP).
- [x] **Code review for security done.** This pass.
- n/a **Penetration testing.** Not proportionate before launch. Revisit once there are real users.
- [ ] **Dependency audit done.** The audit itself is clean, but **Dependabot alerts and security updates are disabled**. → Repo Settings → Code security → enable both.

### Changes made in this pass

- `backend/src/app.js`: security headers (HSTS, nosniff, CSP), plus a test in `backend/test/app.test.js` (backend 19/19 pass).
- `lib/services/api_service.dart`: release builds throw when `API_BASE_URL` isn't `https://` (`flutter analyze` clean, 58/58 tests pass).
- `.github/workflows/ci.yml`: `permissions: contents: read`.

> This repo is **public**. Keep this file uncommitted until B1 is done, because it describes a live, unrotated key.

---

## 2. Performance

**Date:** 2026-10-11 · **Checked by:** Claude (Opus 5.5) for Shubham Ambastha · **Scope:** branch `perf/deploy-checklist`, live API, Supabase project `expense-tracker` (Free plan, `ap-south-1`)

### Blockers: fix before release

| # | Item | Action |
| --- | --- | --- |
| P1 | **Saving a budget fails for every signed-in user.** `POST /v1/budgets` upserts `ON CONFLICT (user_id, category_name)`, but the only unique index is on `lower(category_name)`. A plan-only `EXPLAIN` on the live DB returns `42P10`. Broken since `20260527_dashboard_data.sql`. Guest mode hides it, since it never hits Postgres. Prod confirms it: 2 users with transactions, 0 budgets. | ✅ **Fixed 2026-10-11:** [`sql/20261011_perf_indexes.sql`](../sql/20261011_perf_indexes.sql) is applied. `EXPLAIN` now arbitrates on `category_budgets_user_category_key`, and a rolled-back upsert-twice test leaves 1 row with the new limit. |
| P2 | **Supabase Free plan hibernates idle projects.** On first contact today the project was hibernated, and the first two queries failed with connection timeouts while it woke. Real users would get 500s once the backend's 10 s Supabase timeout trips. | Upgrade to Pro before launch, or accept cold-start failures plus a keep-warm ping. |

### Database

- n/a **Slow query log analyzed.** Production holds only dev data (2 users, 10 transactions; the "0 rows" I first reported came from stale `pg_stat` estimates), far too little for a slow-query log. → Re-check Supabase → Reports → Query Performance after launch.
- [x] **Indexes created/optimized.** Every API query was mapped to an index: each list is a `user_id` filter + one ordered index, PATCH/DELETE hit the PK, and both upsert targets are covered (`recurring_events` was confirmed via `EXPLAIN`). The migration **adds** the 2 FK indexes the advisor flagged (`transactions.transfer_to_account_id`, `accounts.linked_account_id`). Without them, every account delete seq-scans all users' rows. It also **drops** 6 indexes no query uses (4 `transactions` recurring/kind indexes plus 2 `(user_id)` indexes covered by wider ones).
- [x] **N+1 queries eliminated.** The server has none: one query per request, and lists page 1,000 rows at a time. The client has one exception: the one-time guest→account migration posts rows one by one, since it needs the returned ids to remap references ([guest_migration_service.dart](../lib/services/guest_migration_service.dart)). Fine for trial-sized data. Batch it if guests start bringing hundreds of rows.
- [x] **Query execution plans reviewed.** Upsert arbitration was checked with `EXPLAIN` on the live DB (that's how P1 surfaced). RLS policies wrap `requesting_user_id()` in `(SELECT …)`, so it's evaluated once per query, not per row. The advisor's 20 "multiple permissive policies" warnings are fixed by dropping the 4 duplicate INSERT policies. Each table's `FOR ALL` policy already enforces the same check on insert.
- [x] **Connection pooling configured.** The API never opens Postgres connections. It calls PostgREST over HTTPS, PostgREST pools on Supabase's side, and Node's `fetch` keeps connections alive. A fresh client per request costs about 0.4 ms in total (measured, see load test).

### Caching

- n/a **Caching layer (Redis/Memcached).** Every read is one indexed, per-user query, and there's no shared data to cache. Revisit if Supabase latency or cost shows up in metrics.
- n/a **Cache invalidation strategy.** No cache.
- n/a **Cache TTLs.** No cache.
- n/a **HTTP caching headers.** All responses are private, per-user and change on every write, and the app doesn't cache HTTP. Express's default weak `ETag` is harmless.
- n/a **CDN.** The API serves no static assets. App binaries ship through the stores.

### Code optimization

- [x] **Hot paths profiled.** *API:* see the load test. *App:* benchmarked the aggregations that rerun on every `build()`. Analytics took 1.2 ms at 1,500 transactions and 2.9 ms at 5,000; Home took 0.08 ms and 0.24 ms. That was desktop JIT, so expect several times slower on a mid-range phone, still under a 16 ms frame up to about 5k. [analytics_content.dart](../lib/components/analytics/analytics_content.dart) already notes the isolate escape hatch. **Fixed:** the home screen loaded transactions → accounts → budgets one after another on every launch and pull-to-refresh. It now uses one parallel `Future.wait`, saving two network round trips, and each call keeps its own error handling.
- [x] **Memory usage optimized.** Lists are held once in `ExpenseHomePage` state and writes patch them in place (no refetch). The API buffers one list in memory, about 2.4 MB at 5k rows.
- n/a **String operations optimized.** No string-heavy paths.
- [x] **Algorithm complexity acceptable.** No quadratic scans over transactions in `lib/utils/*` (grep plus the benchmark above). Server paging uses `OFFSET`, fine at a few thousand rows per user.
- [x] **Dead code removed.** **Removed** 2 widgets nothing references (`transaction_details_card.dart`, `accounts_settings_section.dart`, about 500 lines) and the unused `animations` package. Kept 4 parked files that docs/TODOS still reference (`SourcePayerField`, `AccountChipsSelector`, `IncomeCategoryPillsSelector`, `validators.dart`). Dart AOT tree-shakes them out of release builds anyway.

### Assets

- n/a **JavaScript minified / CSS minified.** Native Flutter app with AOT compilation, and release builds tree-shake icon fonts.
- [x] **Images compressed.** `assets/` is empty. App icons total 92 KB on iOS and 36 KB on Android, with no PNG over 100 KB.
- n/a **Asset versioning.** No web assets.
- [x] **Lazy loading configured.** Lists render through builders, and the API returns full lists by design (see pagination).

### API performance

- [x] **Response size optimized.** Rows carry only table columns, with no joins or embedded resources.
- [x] **Payload compression enabled.** **Fixed:** added `compression`. Dart's `HttpClient` already sends `Accept-Encoding: gzip` and inflates transparently, so the app needs no change. 1,500 transactions went from **735 KB to 26 KB on the wire** (synthetic data; expect 85–90% savings on real data) with no measurable throughput cost. Tested.
- [ ] **Pagination implemented.** Server-side only: `sendAll` pages through Supabase's 1,000-row cap, then returns everything ([BACKEND.md trade-offs](./BACKEND.md#trade-offs--what-to-revisit)). Each extra 1,000 rows adds one sequential DB round trip, about 60 ms Singapore↔Mumbai. → Add paginated or aggregate endpoints once heavy users pass about 5k transactions.
- n/a **Field filtering.** The client uses every column.

### Load testing

Production wasn't load-tested: I had no auth token, and I wasn't going to stress your live service. Instead I ran the **real API locally** with Auth0 and Supabase stubbed, so these numbers are the Node layer's ceiling on one core (Apple Silicon; Railway's shared vCPU will be lower):

| Payload | DB latency | c=1 | c=10 | c=50 | c=200 |
| --- | --- | --- | --- | --- | --- |
| 100 rows | 0 ms | 391 rps · p50 2.5 ms | 2,330 · 4.1 ms | 2,529 · 19 ms | 2,456 · 80 ms |
| 1,500 rows | 0 ms | 120 · 8 ms | 249 · 39 ms | 259 · 192 ms | 269 · 727 ms |
| 100 rows | 60 ms | 15 · 69 ms | 142 · 70 ms | 621 · 82 ms | 1,594 · 128 ms |
| 1,500 rows | 60 ms | 7 · 145 ms | 64 · 158 ms | 190 · 261 ms | 246 · 857 ms |

- [x] **Load test completed.** API layer only; zero errors at every level.
- [x] **Response times acceptable.** At realistic DB latency, p50 is 70–160 ms per request.
- [x] **Stress test completed.** Up to c=200 locally.
- [x] **Breaking point identified.** CPU-bound JSON parse and stringify. One process tops out around **2,500 req/s for small lists** and **about 260 full-list fetches/s for 1,500-transaction users**. At one full fetch per app open, that's far beyond launch traffic. Supabase Free plan limits come first.
- [ ] **Scaling strategy verified.** The API is stateless (no sessions or memory caches), so Railway replicas scale horizontally. → Not exercised, and the Supabase plan is the real ceiling (see P2).

### Monitoring

- [ ] **Response time tracking enabled.** The app emits no timing metrics. → Check that Railway's HTTP logs show request durations (I can't reach Railway from here).
- [ ] **Performance dashboards created.** Only the built-ins exist: Railway service metrics (CPU, memory, network) and Supabase Reports. Enough for launch.
- [ ] **Performance alerts configured.** None. → Add a free external uptime check on `/health` (1-minute interval) plus Railway usage alerts.
- [x] **Baseline metrics recorded.** Prod `/health`, observed from my machine through Railway's `sin1` edge: p50 TTFB 457 ms on a cold connection (TCP+TLS), **41 ms per request on a warm keep-alive connection**. JWT verification adds nothing measurable (401 path: 431 ms cold). The local API-layer numbers are in the table above.

### Changes made in this pass

- `backend/src/app.js` + `package.json`: `compression` middleware, with a test (backend 20/20 pass).
- `lib/screens/home/expense_home_page.dart`: parallel initial load.
- Removed 2 dead widgets and the unused `animations` dependency (`flutter analyze` clean, 58/58 tests pass).
- `sql/20261011_perf_indexes.sql` + `docs/DATABASE_SCHEMA.md` apply order. **Applied to prod 2026-10-11** and verified. Advisors went from 22 unindexed-FK and duplicate-policy findings to 0. The 10 remaining "unused index" notes are indexes the API needs that haven't seen traffic yet. An RLS test run as `authenticated` (rolled back, 0 rows persisted): own inserts succeed on all 4 tables; NULL-user, other-user and reassign-own-row writes are all denied with `42501`.

---

## 3. Monitoring & alerting

**Date:** 2026-10-11 · **Configured by:** Claude (Opus 5.5) for Shubham Ambastha (code side) · **Tested by:** pending your uptime-monitor setup · **Scope:** branch `ops/monitoring` on `main` @ `d61ab2e`

### Top actions

| # | Item | Action |
| --- | --- | --- |
| M1 | **Nothing alerts you today.** Railway's health check only gates deploys. If the API or Supabase goes down, nobody knows until a user complains. | After this branch deploys: add a free external uptime monitor (UptimeRobot or Better Stack) on `GET /health/db` with the shortest free interval, sending email **and** phone push. Then test it (see Alerting). |
| M2 | **App-side errors are invisible.** There's no crash or error SDK, Flutter shows uncaught Dart exceptions as a grey screen, and nothing reports them. Store consoles (Xcode Organizer, Play vitals) only see native crashes. | **Declined 2026-10-11:** no error SDK for now. Accepted gap: Dart errors and error-rate spikes stay invisible. Rely on the uptime monitor, Railway `@level:error` logs and user reports. Revisit once real users arrive. |
| M3 | **Schema drift: `user_settings.onboarding_completed_at` is missing in prod.** `20260824_onboarding_completed_at.sql` was never applied (checked all 47 API-writable columns against the live DB; this is the only gap). `markOnboardingComplete()` fails silently with a 400, so existing users get the onboarding wizard again on reinstall or a new device. | ✅ **Fixed 2026-10-11:** applied. Re-check: 0 of 47 API columns missing, 5 of 5 rows backfilled, PostgREST serves the column, and the app's upsert works as `authenticated` (rolled back). |

### Metrics collection

- [x] **Application metrics configured.** **Added:** one JSON log line per request with `level`, `method`, `path` (ids collapsed to `:id`), `status`, `ms`, `user`. Status, latency and per-route error rates all come from the logs. There's no separate metrics store, which is right at this size.
- [x] **Infrastructure metrics configured.** Railway's built-in service metrics (CPU, memory, network).
- [x] **Database metrics configured.** Supabase Reports (API, database, query performance) are built in. **Added** `/health/db`, so DB reachability becomes an external signal too.
- [x] **Business metrics configured.** Auth0 Activity for signups and logins, plus two SQL queries in [RUNBOOK.md](./RUNBOOK.md#business-metrics), both run against prod. **Baseline 2026-10-11:** 5 users, 2 with transactions, 0 with budgets (the budget bug, now fixed), 0 weekly active.
- n/a **Custom metrics defined.** The log fields cover them. Revisit with Sentry.

### Log aggregation

- [x] **Logs centralized.** Per platform: Railway (API), Supabase (DB, PostgREST), Auth0 (login). No single aggregator, which is fine for one service. Sentry or a log drain becomes the hub later.
- [x] **Log parsing configured.** Single-line JSON with `level` and `message`, which Railway turns into filterable attributes (`@level:error`, `@path:…`). → Check once with `@level:error` after deploy.
- [x] **Sensitive data masked.** Headers and bodies are never logged, so neither are the bearer token or financial data. Error lines leave out PostgREST `details`/`hint`, which can echo whole rows. A test asserts the token never appears in a log line. `user` is the Auth0 `sub`, a pseudonymous id kept deliberately so support emails (which include it) can be traced.
- [ ] **Log retention defined.** Supabase keeps **about 24 h** (observed, Free). Railway and Auth0 retention depend on the plan. → Check both plans. 24 h on DB logs is the weak spot, so Railway's API logs are the record.
- [ ] **Log access restricted.** Only dashboard members can read logs. → Confirm you're the only member on Railway, Supabase and Auth0, with MFA on (security section).

### Alerting

- [ ] **Service down alert.** → M1. `/health/db` fails if either Node or Supabase is down. *(As a side effect, pinging every few minutes keeps Supabase active. Still upgrade to Pro for launch rather than rely on that.)*
- n/a **High error rate alert.** Not possible from stdout logs alone, and Sentry was declined (M2). Check `@level:error` in Railway after each deploy instead.
- [ ] **Performance degradation alert.** → Set a response-time threshold on the uptime monitor (e.g. alert above 3 s). Sentry performance later.
- [ ] **High CPU/memory alert.** → Railway: see whether your plan offers resource alerts. At minimum, set a usage limit/alert in workspace billing.
- [ ] **Database alerts.** Outage and hibernation are covered by `/health/db` (M1). Supabase emails automatically when quota limits get close.
- [ ] **Alert testing completed.** After setting up M1, point the monitor at `/health/nope` (always 404) once and confirm both email and push arrive, then point it back.

### Dashboards

- [x] **System health dashboard.** Railway service metrics plus Supabase Reports (built in).
- [x] **Performance dashboard.** The same, plus the `ms` field per `@path` in Railway logs.
- [ ] **Business metrics dashboard.** SQL queries only (save them as Supabase SQL snippets). A charted dashboard isn't worth it at 5 users.
- [x] **Troubleshooting dashboard.** [RUNBOOK.md](./RUNBOOK.md) has the log filters and a symptom → cause → fix table.

### Monitoring tools

- [x] **Monitoring tool deployed.** Platform built-ins only. Uptime monitor (M1) and Sentry (M2) are pending your setup.
- n/a **Agent/collector configured.** PaaS: Railway captures stdout, so there's no agent to run.
- [ ] **Data retention set.** See log retention.
- [x] **Visualization enabled.** The built-in dashboards.

### Incident response

- [x] **Runbooks created.** [`docs/RUNBOOK.md`](./RUNBOOK.md): where each signal lives, health endpoints, log filters, 11 symptom → cause → fix rows (including rollback = Railway redeploy of the last good deployment, and the "missing migration" signature `42703`/`PGRST204`), and business-metrics SQL.
- n/a **On-call rotation setup.** Solo project, so you're on call. What matters is that M1 alerts reach your phone.
- [x] **Escalation paths defined.** Vendor status pages and support, in the runbook.
- [ ] **Alert notifications tested.** Pending M1.

### Changes made in this pass

- `backend/src/app.js`: JSON request log (skips `/health*`) and `GET /health/db` (anonymous query, RLS returns nothing, no retries, so it fails fast). Checked live: the anonymous query returns `[]` from prod.
- `backend/src/middleware/errors.js`: JSON error lines that leave out `details`/`hint`.
- `backend/src/db.js`: the `anon` client. Tests: 2 new (log shape and token masking; `/health/db` up/down), 22/22 pass.
- `docs/RUNBOOK.md` (new), plus `docs/BACKEND.md` (Logs section, endpoint, trade-off) and `CLAUDE.md` (docs table).
