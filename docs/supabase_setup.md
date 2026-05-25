# Supabase setup and CI notes

## GitHub Actions

The workflow at `.github/workflows/ci.yml` uses repository Secrets to inject Supabase keys at build time.

Add the following secrets in your GitHub repository settings -> Secrets:
- `SUPABASE_URL` — your project URL (e.g. `https://abcd1234.supabase.co`)
- `SUPABASE_ANON_KEY` — the anon/public key (never expose the service role key)

The workflow passes these as `--dart-define=KEY=VALUE` to `flutter build`.

## Database schema

### Fresh setup (run in order)

| # | File | Creates |
|---|------|---------|
| 1 | `sql/expenses_table.sql` | `expenses` (legacy) + `accounts` + RLS |
| 2 | `sql/20260517_add_named_accounts.sql` | `accounts` FK on `expenses` |
| 3 | `sql/20260517_normalize_expense_accounts.sql` | Drops stale `account_name/type` columns |
| 4 | `sql/user_settings_table.sql` | `user_settings` (default currency) |
| 5 | `sql/expense_categories_table.sql` | `expense_categories` + RLS |
| 6 | `sql/20260526_create_transactions.sql` | `transactions` unified ledger + backfill from `expenses` |
| 7 | `sql/20260526_income_categories.sql` | `income_categories` + seeds for all existing users |
| 8 | `sql/20260526_counterparties.sql` | `counterparties` autofill history + backfill from `expenses.name` |

### Existing databases (apply only the new migrations)

If you have an existing database with the first five files already applied, run only files 6–8.

### Table overview

```
accounts                  — bank / wallet / cash / UPI accounts
user_settings             — per-user default currency
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

The app stores amounts as numbers; `user_settings.default_currency_code` controls display and input formatting per account.

### Notes
- Every table has `user_id uuid NOT NULL REFERENCES auth.users(id)` and RLS enabled.
- Use `auth.uid()` in policies to scope rows to the authenticated user.
- For single-user or early prototyping you can omit RLS, but always enable it in production.

## RLS guidance

- Use anon key only for client operations you intend to allow.
- Never put `service_role` key in the client or in public repos.
- For privileged operations, implement a secure backend function (server) that uses the `service_role` key.

## Local development

You can use `scripts/define_from_json.py` to run flutter with `--dart-define` values read from a local JSON file (ignore that file in git). Example:

```bash
cp config.dev.json.example config.dev.json
# edit config.dev.json with your keys
python3 scripts/define_from_json.py config.dev.json run
```

*** End Patch