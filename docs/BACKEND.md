# Backend API

Node service in [`backend/`](../backend/) that the Flutter app uses for all data access. The app no longer talks to Supabase. It signs in with Supabase Auth, calls this REST API with the Supabase access token, and the API reads and writes Supabase Postgres on the user's behalf.

> **Security boundary:** Postgres RLS is still the real enforcement point. The app ships the publishable key (it needs it for Supabase Auth), so anyone with a valid login can still call PostgREST without going through this API. Treat the API's whitelists and checks as advisory until direct table access is revoked. See the trade-offs below.

See also: [ARCHITECTURE.md](./ARCHITECTURE.md) (app side), [DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md) (tables), [supabase_setup.md](./supabase_setup.md) (auth providers).

---

## Shape

```
┌──────────────┐  Bearer <access token>    ┌────────────────────────┐  same token   ┌───────────────────┐
│ Flutter app  │ ────────────────────────▶ │ backend/ (Express 5)   │ ────────────▶ │ Supabase Postgres │
│ ApiService   │ ◀──────── JSON ───────── │ 1. verify JWT (JWKS)   │ ◀──────────── │ RLS: user_id =    │
└──────┬───────┘                           │ 2. user_id := sub      │   PostgREST   │   jwt.sub         │
       │ guest mode                        │ 3. whitelist columns   │               └───────────────────┘
       ▼                                   └────────────────────────┘
  GuestStore (on-device, no network)               ▲ JWKS
                                                   │
                                   Supabase /auth/v1/.well-known/jwks.json
```

Two layers scope every row to the signed-in user:

1. **API**: verifies the token against Supabase Auth's JWKS (issuer `<SUPABASE_URL>/auth/v1`, audience `authenticated`, ES256 or RS256; anonymous-user tokens are rejected), then forces `user_id = sub` on every insert and adds `.eq('user_id', sub)` to every read, update and delete. Clients can't set `id` or `user_id`, and any column not on the per-table whitelist is dropped.
2. **Postgres RLS**: the API forwards the caller's own token to Supabase, so the existing `user_id = requesting_user_id()` policies still apply. A bug in the API can't read another user's rows.

## Why REST, not GraphQL

| | REST (chosen) | GraphQL |
| --- | --- | --- |
| Fit | ~20 operations map 1:1 to the old `SupabaseService` methods | Built for clients picking fields across nested graphs. This app fetches whole lists and aggregates on-device |
| Client | `package:http` + `jsonDecode`, same `fromMap` models | Needs a GraphQL client, query documents, usually codegen |
| Server | Express routes, 3 deps | Schema, resolvers, N+1 batching (dataloader) |
| Caching/debug | Plain HTTP status codes, curl-able | Everything is `POST /graphql` with 200 + `errors[]` |

Reconsider GraphQL if a second client (web dashboard) needs very different slices of the same data.

## Endpoints

All under `/v1`, all require `Authorization: Bearer <token>`. Bodies are the same snake_case maps the Dart models' `toMap()` / `fromMap()` already use.

| Method & path | Dart caller (`ApiService`) | Notes |
| --- | --- | --- |
| `GET /transactions` | `fetchTransactions` | newest first |
| `POST /transactions` | `insertTransaction` | 201 |
| `PATCH /transactions/:id` | `updateTransaction`, `setTransactionPaused`, `setTransactionClosed` | partial update |
| `DELETE /transactions/:id` | `deleteTransaction` | 204 |
| `GET /recurring-events` | `fetchRecurringEvents` | |
| `POST /recurring-events` | `insertRecurringEvent` | upsert on `(user, txn, date, type)` |
| `DELETE /recurring-events/:id` | `deleteRecurringEvent` | |
| `GET /accounts[?includeArchived=true]` | `fetchAccounts` | archived hidden by default |
| `POST /accounts` · `PATCH /accounts/:id` · `DELETE /accounts/:id` | `insertAccount`, `updateAccount`/`archiveAccount`, `deleteAccount` | |
| `GET /budgets` · `POST /budgets` · `DELETE /budgets/:id` | `fetchCategoryBudgets`, `upsertCategoryBudget`, `deleteCategoryBudget` | POST upserts on category name |
| `GET /categories/{expense,income}` | `fetchCategories`, `fetchIncomeCategories` | |
| `POST /categories/{expense,income}` | `insertCategory`, `insertIncomeCategory`, `ensureDefault…Categories` | object, or array for seeding |
| `DELETE /categories/{expense,income}/:id` | `deleteCategory`, `deleteIncomeCategory` | seeded defaults are never deleted |
| `GET /settings` | `fetchUserSettings` (also read for `onboardingCompletedAt`) | row or `null` |
| `PATCH /settings` | `upsertUserSettings`, `markOnboardingComplete` | upserts only the columns sent |
| `DELETE /data` | `resetUserData` | "Reset My Account", keeps settings |
| `POST /data/export` | `emailDataExport` | "Export Data": emails transactions, accounts (incl. archived) and budgets as CSV attachments to the token's `email` via Resend. 202 `{ email }`; 400 if the token has no email, 502 if Resend refuses, 503 if `RESEND_API_KEY` / `EXPORT_FROM_EMAIL` are unset |
| `DELETE /account` | `deleteUserAccount` | "Delete Account": every row incl. settings, then the Supabase auth user (service-role key). The user goes last, so a failure part-way can be retried |
| `GET /health` | — | unauthenticated liveness check for the host (Node is up) |
| `GET /health/db` | — | unauthenticated, for an external uptime monitor: 200 only if Supabase answers too (anonymous query, RLS returns no rows, no retries) |

Errors are JSON `{ "error": "...", "code": "<postgres/PostgREST code>" }`. Status codes:

- **401:** bad, expired or missing token, or Supabase rejecting the forwarded token (`PGRST301`).
- **404 on PATCH:** the row is missing or belongs to someone else. Any non-numeric `:id` is also a 404.
- **413:** request body over 1 MB.
- **Other 4xx:** passed through from PostgREST, e.g. 400 for bad input or constraint errors, 403 for an RLS denial, 409 for unique/FK conflicts.
- **500:** anything else, including a Supabase JWKS or Supabase outage, or the auth user failing to delete.

`error` is a fixed, user-safe message per status (e.g. 409 → "That already exists or is still in use."). Raw Postgres messages name constraints and indexes, so they only go to the server log.

DELETE is idempotent: it returns 204 even when nothing matched, including attempts to delete a seeded default category, same as the old direct-Supabase behavior. Every Supabase call times out after 10s and every app request after 20s. The app surfaces `error` through `ApiException.toString()` → `SnackbarHelper.showError`.

## Code layout

```
backend/src/
├── server.js            # listen on PORT
├── app.js               # express app: JSON body, /health, /v1, 404, error handler
├── config.js            # required env, checked at import (missing → crash on boot)
├── db.js                # per-request Supabase client + helpers: must/send/sendAll, pick, list/updateOwn/deleteOwn/row
├── middleware/
│   ├── auth.js          # Supabase access token → req.userId, req.db
│   └── errors.js        # JSON 404 + error handler (fixed user-safe messages)
└── routes/
    ├── index.js         # /v1 router: auth, then mounts each resource
    ├── resource-router.js  # Router whose :id must be a bigint
    ├── transactions.js · recurring-events.js · accounts.js · budgets.js
    ├── categories.js    # one factory, mounted for expense_ and income_categories
    └── settings.js · data.js · account.js
```

Each route file owns its table's column whitelist. To add an entity: write `routes/<resource>.js` with `resourceRouter()` and the `db.js` helpers (they scope every query to `req.userId`), then mount it in `routes/index.js`.

There is no controller/service layer. Every handler is one scoped query, so a service layer would only pass arguments through. Add one when a route gains real logic, e.g. multi-step writes.

## Run locally

```bash
cd backend
cp .env.example .env   # SUPABASE_URL / SUPABASE_ANON_KEY / SUPABASE_SERVICE_ROLE_KEY
npm install
npm run dev            # http://localhost:3000, restarts on change
npm test
```

Then set `API_BASE_URL` in `config.dev.json` to match where the app runs:

| App runs on | `API_BASE_URL` |
| --- | --- |
| iOS simulator / macOS | `http://localhost:3000` |
| Android emulator | `http://10.0.2.2:3000` (debug manifest allows cleartext) |
| Physical device | `http://<your-LAN-IP>:3000`, or a deployed HTTPS URL |

## Deploy

Any Node 22+ host (Render, Railway, Fly.io, a VM): `npm ci && npm start`, set the env vars from `.env.example` (the two Resend ones are optional; without them only Export Data 503s) (`PORT` is usually injected by the host), and point the host's health check at `/health`. Point an external uptime monitor at `/health/db` instead, so it also catches a Supabase outage. Release builds need an **HTTPS** `API_BASE_URL` set as the `API_BASE_URL` GitHub secret for CI.

Data routes use the Supabase **anon** key plus the user's token, so RLS applies. The **service-role** key is used only by `DELETE /v1/account` to remove the auth user, but a leaked backend env *can* bypass RLS, so treat it as a top-tier secret.

## Logs

Each request writes one JSON line to stdout: `level`, `message`, `method`, `path` (numeric ids collapsed to `:id`), `status`, `ms`, `user` (Supabase user id, absent on 401). `/health*` is skipped. Errors add a second line with `message`, `code`, `status`, plus `stack` on 5xx. Headers, bodies, and PostgREST's `details`/`hint` are never logged: those carry the bearer token or echo a whole row of someone's finances. On Railway, filter with `@level:error`, `@status:500`, `@path:/v1/budgets`, `@user:"<uuid>"`. Incident steps are in [RUNBOOK.md](./RUNBOOK.md).

## Trade-offs & what to revisit

| Decision | Why now | Revisit when |
| --- | --- | --- |
| Forward user token to Supabase (RLS stays on) | Defense in depth; the service-role key is confined to account deletion | Before switching `createClient` to the service-role key, revoke direct table access for `anon`/`authenticated` and move integrity rules (e.g. FK ownership) into Postgres. Until then RLS is the only enforced guard |
| `supabase-js` as the DB client | Near line-for-line port of the old Dart queries | You leave Supabase. Swap to `pg`/`postgres.js` + `DATABASE_URL` |
| `DELETE /data` deletes table by table | Same behavior as before | Partial wipes become a real problem. Move to a single Postgres function (one transaction) |
| Category default seeds stay in Dart | Guest mode needs the same seed list on-device | Seeding moves fully server-side (e.g. on first `GET /settings`) |
| Client still aggregates dashboards/analytics; list endpoints page through Supabase's `max_rows` cap server-side and return everything | Unchanged, all logic stays in `lib/utils/*_aggregations.dart` | Transaction counts make full-list fetches slow. Add paginated/aggregate endpoints |
| No rate limiting or CORS | Mobile-only client, small user base | Opening to web clients (add CORS) or seeing abuse (add `express-rate-limit`) |
| Logs are stdout JSON only (no APM, no log drain) | Railway parses JSON lines into filterable fields for free | You need alerting on error rate or latency. Add Sentry or a log drain |
