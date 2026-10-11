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

The workflow passes these as `--dart-define=KEY=VALUE` to `flutter build`.

## Database schema

### Fresh setup (run in order)

| # | File | Creates |
|---|------|---------|
| 1 | `sql/expenses_table.sql` | `expenses` (legacy) + `accounts` + RLS |
| 2 | `sql/20260517_add_named_accounts.sql` | `accounts` FK on `expenses` |
| 3 | `sql/20260517_normalize_expense_accounts.sql` | Drops stale `account_name/type` columns |
| 4 | `sql/user_settings_table.sql` | `user_settings` (default currency + `preferences` jsonb) |
| 4b | `sql/20260527_user_settings_preferences.sql` | Adds `preferences` to existing `user_settings` (skip if table created from updated file 4) |
| 5 | `sql/expense_categories_table.sql` | `expense_categories` + RLS |
| 6 | `sql/20260526_create_transactions.sql` | `transactions` unified ledger + backfill from `expenses` |
| 7 | `sql/20260526_income_categories.sql` | `income_categories` + seeds for all existing users (required for Settings → Categories income labels) |
| 8 | `sql/20260526_counterparties.sql` | `counterparties` autofill history + backfill from `expenses.name` |

### Existing databases (apply only the new migrations)

If you have an existing database with the first five files already applied, run migrations 4b (if `preferences` is missing), then 6–8 as needed.

| # | File | Purpose |
|---|------|---------|
| 9 | `sql/20260529_auth0_user_id_text.sql` | Auth0: `user_id` → text, drop `auth.users` FKs, RLS uses `requesting_user_id()` |

Run migration 9 before using the Auth0-enabled app against an existing database (dev-only: no user migration from Supabase Auth UUIDs).

### Table overview

```
accounts                  — bank / wallet / cash / UPI accounts
user_settings             — per-user default currency + `preferences` (jsonb app settings)
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
counterparties            — pinned payer/merchant history for autofill chips
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

The app stores amounts as numbers; `user_settings.default_currency_code` controls display and input formatting per account. `user_settings.preferences` stores the same keys as local `SettingsPreferences` (multi-currency, budgets, notifications, theme, etc.) for cross-device sync when signed in.

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

*** End Patch