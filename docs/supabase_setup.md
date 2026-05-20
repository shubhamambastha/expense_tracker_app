# Supabase setup and CI notes

## GitHub Actions

The workflow at `.github/workflows/ci.yml` uses repository Secrets to inject Supabase keys at build time.

Add the following secrets in your GitHub repository settings -> Secrets:
- `SUPABASE_URL` — your project URL (e.g. `https://abcd1234.supabase.co`)
- `SUPABASE_ANON_KEY` — the anon/public key (never expose the service role key)

The workflow passes these as `--dart-define=KEY=VALUE` to `flutter build`.

## Database schema

Run these SQL files in the Supabase SQL editor (in order if setting up fresh):

- `sql/expenses_table.sql` — expenses table and RLS
- `sql/20260517_add_named_accounts.sql` — accounts table
- `sql/user_settings_table.sql` — per-user default currency (`default_currency_code`)

The app stores amounts as numbers; `user_settings.default_currency_code` controls display and input formatting per account.

Notes:
- The migration includes a `user_id uuid` column. Use `auth.uid()` in policies to scope rows to the authenticated user.
- For single-user or early prototyping you can omit RLS, but in production always enable RLS and restrict access.

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