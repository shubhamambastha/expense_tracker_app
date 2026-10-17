# Supabase setup and CI notes

See also: [DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md) (mind-map schema reference), [ARCHITECTURE.md](./ARCHITECTURE.md) (app structure).

## Authentication (Supabase Auth)

Login uses **Supabase Auth**: email + password (confirmed with an emailed 6-digit code), native Google sign-in, and Sign in with Apple on iOS. The Flutter app talks to Supabase **only for auth** (`AuthService`, with the publishable key). Every data read and write still goes through the Node API ([BACKEND.md](./BACKEND.md)), which verifies the Supabase access token and forwards it so RLS applies. `user_id` columns are **text** holding the user's UUID (the JWT `sub`).

### 1. JWT signing keys

Settings → **JWT Keys** → move the project to **asymmetric signing keys** (ES256). The API verifies tokens against `https://<project>.supabase.co/auth/v1/.well-known/jwks.json`; legacy HS256 tokens won't verify.

### 2. Email + password

Authentication → **Providers → Email**:
- Enable **Email**, **Confirm email** on, minimum password length **8** (matches `minPasswordLength` in `lib/utils/validators.dart`).
- Authentication → **Email Templates**: in **Confirm signup** and **Reset password**, show the code instead of a link, e.g. `<p>Your code: <strong>{{ .Token }}</strong></p>`. The app has no auth deep links, so a link-only template leaves users stuck.
- Authentication → **SMTP Settings**: set up a real sender (Resend, SES, Postmark) **before launch**. The built-in sender is heavily rate-limited and meant for testing.
- Harden the codes, since the publishable key ships in the app and anyone can call `/auth/v1/signup`, `/recover` and `/verify` directly: **Email OTP expiration ~600 s** (default 3600), consider **OTP length 8** (`validateCode` accepts 6–10), tight **email rate limits** (Authentication → Rate Limits), and **CAPTCHA** (hCaptcha/Turnstile) before a public launch.
- Leave **Anonymous sign-ins off**. The API rejects anonymous tokens anyway.

### 3. Google

1. Google Cloud → APIs & Services → Credentials → create three OAuth clients:
   - **Web application**: its client ID is `GOOGLE_WEB_CLIENT_ID`, and its client ID + secret go into Supabase.
   - **iOS** (bundle id `com.cremarsservices.jebbo`): its client ID is `GOOGLE_IOS_CLIENT_ID`. In `ios/Runner/Info.plist`, replace `REPLACE_WITH_IOS_CLIENT_ID` so the URL scheme becomes the *reversed* client ID (`com.googleusercontent.apps.<id>`).
   - **Android** (package `com.cremarsservices.jebbo` + the SHA-1 of every signing key: `cd android && ./gradlew signingReport`). No value goes in the app; Google matches it by package + SHA-1.
2. Supabase → Providers → **Google**: enable, paste the Web client ID + secret, add the iOS client ID under **Authorized Client IDs** (comma-separated after the web one), and turn on **Skip nonce check** (the iOS SDK adds a nonce the app can't see).

### 4. Apple (iOS only)

1. Apple Developer → Identifiers → the app's App ID → enable **Sign in with Apple**. (`ios/Runner/Runner.entitlements` already declares it.)
2. Supabase → Providers → **Apple**: enable and add `com.cremarsservices.jebbo` under **Client IDs**. No secret key is needed for the native flow.

Apple shares the user's name only on the first authorization; `AuthService.signInWithApple` saves it to `user_metadata.full_name` right away.

### 5. Account deletion

`DELETE /v1/account` removes the user's rows (as the user, through RLS) and then the auth user, using the **service role** key (`SUPABASE_SERVICE_ROLE_KEY` on the backend host only). Apply `sql/20261012_user_settings_delete_policy.sql` first: without a DELETE policy the settings row can't be removed, and the route refuses to delete the login.

### 6. Export Data Edge Function

Settings → Export Data goes app → `POST /v1/data/export` → `supabase/functions/export-data`, which emails the user's CSVs through [Resend](https://resend.com). One-time setup (Supabase CLI):

```bash
supabase link --project-ref YOUR_PROJECT_ID
supabase secrets set RESEND_API_KEY=re_... EXPORT_FROM_EMAIL="Expense Tracker <export@yourdomain.com>"
supabase functions deploy export-data --no-verify-jwt
```

`EXPORT_FROM_EMAIL` must be on a domain verified in Resend. `--no-verify-jwt` because the project uses asymmetric JWT keys; the function verifies the token itself (`auth.getUser`). Until it is deployed with both secrets, Export Data shows an error (the API answers 502). Errors are in Supabase → Edge Functions → export-data → Logs. CSV helper test: `node --test supabase/functions/export-data/csv.test.ts`.

### Cutover order

See **B4** in [DEPLOY_CHECKLIST.md](./DEPLOY_CHECKLIST.md): set up the dashboard, apply the policy migration and set `SUPABASE_SERVICE_ROLE_KEY` on Railway **before** merging, because Railway auto-deploys `main`.

### Not set up yet

Phone OTP: add later through Providers → Phone with a **Send SMS Hook** (any SMS/WhatsApp provider), plus CAPTCHA and SMS rate limits against SMS-pumping fraud.

## GitHub Actions

The workflow at `.github/workflows/ci.yml` uses repository Secrets to inject keys at build time.

Add the following secrets in your GitHub repository settings -> Secrets:
- `API_BASE_URL` — deployed HTTPS URL of the Node API (Supabase keys live only in the backend host's env, see [BACKEND.md](./BACKEND.md#deploy))
- `SUPABASE_URL` — `https://<project>.supabase.co`
- `SUPABASE_PUBLISHABLE_KEY` — Settings → API Keys → publishable key (safe in the app; RLS guards the rows)
- `GOOGLE_WEB_CLIENT_ID`, `GOOGLE_IOS_CLIENT_ID` — see Google above

The workflow passes these as `--dart-define=KEY=VALUE` to `flutter build`. A separate `backend` job runs `npm ci && npm test` in `backend/` on Node 22 and needs no secrets (the tests stub Supabase).

## Database schema

### Migrations

Run the files in `sql/` in the order listed in [DATABASE_SCHEMA.md → Migration apply order](./DATABASE_SCHEMA.md#migration-apply-order), in the Supabase SQL editor. On an existing database, apply only the files after the last one you ran.

`20260529_auth0_user_id_text.sql` converted `user_id` to text, dropped the `auth.users` FKs, and switched RLS to `requesting_user_id()` (for the former Auth0 login). It still applies: Supabase Auth's `sub` is the UUID as text, so the same policies work unchanged. `20261012_drop_auth0_rows.sql` is the one-off cleanup of rows left by Auth0 users after the switch.

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
- App tables use `user_id text NOT NULL` (the Supabase user's UUID as text). There is no FK to `auth.users`, so deleting a user doesn't cascade: `DELETE /v1/account` deletes the rows first.
- RLS policies use `user_id = (SELECT public.requesting_user_id())` where `requesting_user_id()` reads `auth.jwt() ->> 'sub'`. Don't switch them to `auth.uid()` (uuid) without also converting the columns back to uuid.
- For single-user or early prototyping you can omit RLS, but always enable it in production.

## RLS guidance

- Use anon key only for client operations you intend to allow.
- Never put `service_role` key in the client or in public repos.
- The app reaches Supabase directly only for auth; data goes through the Node API ([BACKEND.md](./BACKEND.md)), which uses the anon key + the user's forwarded token. The publishable key ships in the app, so a signed-in user can still call PostgREST directly, and RLS remains the real enforcement point. Keep it on and correct. The `service_role` key lives only on the backend host (account deletion), never in the app.

## Local development

You can use `scripts/define_from_json.py` to run flutter with `--dart-define` values read from a local JSON file (ignore that file in git). Example:

```bash
cp config.dev.json.example config.dev.json
# edit config.dev.json: API_BASE_URL, SUPABASE_URL + publishable key, Google client IDs
python3 scripts/define_from_json.py config.dev.json run
```