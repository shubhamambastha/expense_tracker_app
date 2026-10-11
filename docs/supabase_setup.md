# Supabase setup and CI notes

See also: [DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md) (mind-map schema reference), [ARCHITECTURE.md](./ARCHITECTURE.md) (app structure).

## Authentication (Auth0)

Login is handled by **Auth0**, not Supabase Auth. See [auth0_setup.md](auth0_setup.md) for dashboard steps.

The Flutter app sends Auth0 **ID tokens** to the Node API ([BACKEND.md](./BACKEND.md)). The API verifies them and forwards them to Supabase, which validates them again via the third-party Auth0 integration. Database `user_id` columns are **text** values matching the JWT `sub` claim (e.g. `auth0|…`).

## GitHub Actions

The workflow at `.github/workflows/ci.yml` uses repository Secrets to inject keys at build time.

Add the following secrets in your GitHub repository settings -> Secrets:
- `API_BASE_URL` — deployed HTTPS URL of the Node API (Supabase keys live only in the backend host's env, see [BACKEND.md](./BACKEND.md#deploy))
- `AUTH0_DOMAIN` — Auth0 tenant domain (e.g. `dev-abc.us.auth0.com`)
- `AUTH0_CLIENT_ID` — Native application client ID

The workflow passes these as `--dart-define=KEY=VALUE` to `flutter build`. A separate `backend` job runs `npm ci && npm test` in `backend/` on Node 22 and needs no secrets (the tests stub Auth0 and Supabase).

## Database schema

### Migrations

Run the files in `sql/` in the order listed in [DATABASE_SCHEMA.md → Migration apply order](./DATABASE_SCHEMA.md#migration-apply-order), in the Supabase SQL editor. On an existing database, apply only the files after the last one you ran.

`20260529_auth0_user_id_text.sql` is required before the Auth0-enabled app works against an older database: it converts `user_id` to text, drops the `auth.users` FKs, and switches RLS to `requesting_user_id()`. Dev-only, so there's no migration of existing Supabase Auth UUID users.

### Table overview

```
accounts                  — bank / wallet / cash / UPI accounts
user_settings             — per-user default currency + `preferences` (jsonb app settings) + `onboarding_completed_at`
expense_categories        — user-customisable expense category pills
income_categories         — user-customisable income category pills
                            (Salary, Freelance, Refund, Bonus, Gift, …)
transactions              — unified ledger for expense + income + transfer
  kind                    expense | income | transfer
  amount / currency_code  money value
  category                → expense_categories.name or income_categories.name
  counterparty_name       merchant (expense) or payer/employer/client (income)
  account_id              → accounts.id  (source for expense/transfer, destination for income)
  transfer_to_account_id  → accounts.id  (destination for transfer only)
  note                    free-text annotation
  is_recurring            recurring toggle
  recurrence_frequency    weekly | monthly | quarterly | yearly | custom | daily
  recurrence_start_date   first occurrence
  recurrence_end_date     last occurrence (null = no end)
  reminder_timing         sameDay | oneDayBefore | twoDaysBefore | oneWeekBefore
  is_paused / closed_at   pause or permanently close a recurring schedule
category_budgets          — monthly limit per expense category name
recurring_events          — paid / skipped / snoozed per occurrence of a recurring transaction
counterparties            — pinned payer/merchant history for autofill chips (not used by the app yet)
  kind                    merchant | employer | client | person | generic
  use_count / last_used_at  ranking signals for suggestion ordering
```

### Legacy `expenses` table

`expenses` is kept intact after the migration as a safety net.
The `transactions` backfill copies every row from `expenses` into `transactions`
with `kind = 'expense'`.  Once the app is fully migrated and verified, drop it:

```sql
DROP TABLE public.expenses;
```

Do **not** drop it before the app is reading from `transactions`.

The app stores amounts as numbers; `user_settings.default_currency_code` controls display and input formatting per account. `user_settings.preferences` stores the same keys as local `SettingsPreferences` (theme, accent, monthly spending limit, budget and notification toggles, etc.) for cross-device sync when signed in.

### Notes
- App tables use `user_id text NOT NULL` (Auth0 `sub`). There is no FK to `auth.users` when using third-party Auth0.
- RLS policies use `user_id = (SELECT public.requesting_user_id())` where `requesting_user_id()` reads `auth.jwt() ->> 'sub'`.
- Do **not** use `auth.uid()` with Auth0 JWTs — `sub` is not a UUID ([Supabase third-party Auth0](https://supabase.com/docs/guides/auth/third-party/auth0)).
- For single-user or early prototyping you can omit RLS, but always enable it in production.

## RLS guidance

- Use anon key only for client operations you intend to allow.
- Never put `service_role` key in the client or in public repos.
- The app only reaches Supabase through the Node API ([BACKEND.md](./BACKEND.md)), which uses the anon key + the user's forwarded token. Supabase still accepts Auth0 tokens directly, though, so RLS remains the real enforcement point. Keep it on and correct. Use the `service_role` key only for privileged server-side jobs, never in the app.

## Local development

You can use `scripts/define_from_json.py` to run flutter with `--dart-define` values read from a local JSON file (ignore that file in git). Example:

```bash
cp config.dev.json.example config.dev.json
# edit config.dev.json: API_BASE_URL + Auth0 keys (Supabase keys go in backend/.env)
python3 scripts/define_from_json.py config.dev.json run
```