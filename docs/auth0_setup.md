# Auth0 + Supabase setup

See also: [supabase_setup.md](./supabase_setup.md), [DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md), [ARCHITECTURE.md](./ARCHITECTURE.md).

Authentication uses **Auth0 Universal Login**; expense data stays in **Supabase** with Row Level Security keyed by the Auth0 JWT `sub` claim.

## 1. Auth0 Dashboard

1. [Auth0 Dashboard](https://manage.auth0.com/) → **Applications** → **Create Application** → type **Native**.
2. Note **Domain** and **Client ID** for `config.dev.json`.
3. **Allowed Callback URLs** and **Allowed Logout URLs** (comma-separated):

```
https://YOUR_DOMAIN/android/com.example.expense_tracker_app/callback
https://YOUR_DOMAIN/ios/com.shubhamambastha.expensetracker/callback
com.shubhamambastha.expensetracker://YOUR_DOMAIN/ios/com.shubhamambastha.expensetracker/callback
https://YOUR_DOMAIN/macos/com.shubhamambastha.expensetracker/callback
com.shubhamambastha.expensetracker://YOUR_DOMAIN/macos/com.shubhamambastha.expensetracker/callback
```

Replace `YOUR_DOMAIN` with your tenant host (e.g. `dev-abc123.us.auth0.com`).

4. **Actions** → **Library** → **Build Custom** → trigger **Login / Post Login**:

```javascript
exports.onExecutePostLogin = async (event, api) => {
  api.idToken.setCustomClaim('role', 'authenticated');
};
```

Deploy the action and add it to the Login flow.

5. Enable **Username-Password-Authentication** (and social providers if desired) for this application.

## 2. Supabase Dashboard

1. **Authentication** → **Third-Party Auth** → add **Auth0** integration (tenant ID + region if prompted).
2. Run [`sql/20260529_auth0_user_id_text.sql`](../sql/20260529_auth0_user_id_text.sql) in the SQL editor on your project (see [supabase_setup.md](supabase_setup.md)).

## 3. Local app config

```bash
cp config.dev.json.example config.dev.json
# Fill SUPABASE_URL, SUPABASE_ANON_KEY, AUTH0_DOMAIN, AUTH0_CLIENT_ID, AUTH0_CALLBACK_SCHEME
python3 scripts/define_from_json.py config.dev.json run
```

Optional Android Gradle property (manifest placeholder for Auth0 redirect):

```properties
# android/local.properties or ~/.gradle/gradle.properties
AUTH0_DOMAIN=dev-abc123.us.auth0.com
```

## 4. iOS / macOS callbacks (default: custom URL scheme)

The app uses a **custom URL scheme** on iOS/macOS (`com.shubhamambastha.expensetracker`, same as `AUTH0_CALLBACK_SCHEME` in `config.dev.json`) so login works without Associated Domains. It must match `ios/Runner/Info.plist` and `macos/Runner/Info.plist` (`CFBundleURLSchemes` under the `auth0` entry). Ensure these URLs are in Auth0 **Allowed Callback URLs** and **Allowed Logout URLs**:

```
com.shubhamambastha.expensetracker://YOUR_DOMAIN/ios/com.shubhamambastha.expensetracker/callback
com.shubhamambastha.expensetracker://YOUR_DOMAIN/macos/com.shubhamambastha.expensetracker/callback
```

If you change the iOS bundle identifier in Xcode, update the scheme, plists, `AUTH0_CALLBACK_SCHEME`, and Auth0 dashboard URLs together.

**Callback not returning to the app?** Checklist:

1. Auth0 **Allowed Callback URLs** and **Allowed Logout URLs** include the exact URLs (comma-separated), e.g. for tenant `dev-0555hmyxvhdoixcw.us.auth0.com`:
   ```
   com.shubhamambastha.expensetracker://dev-0555hmyxvhdoixcw.us.auth0.com/ios/com.shubhamambastha.expensetracker/callback
   ```
2. `config.dev.json` has `AUTH0_CALLBACK_SCHEME` matching `ios/Runner/Info.plist` (`CFBundleURLSchemes` under `auth0`).
3. Run via `python3 scripts/define_from_json.py config.dev.json run` so `--dart-define` values are applied (plain `flutter run` omits them).
4. Delete the app from the simulator/device and reinstall after changing schemes.
5. Remove old `com.example.expenseTrackerApp://…` URLs from Auth0 only after the new URLs work (keeping both temporarily is fine).

(Replace `YOUR_DOMAIN` with your tenant host, e.g. `dev-0555hmyxvhdoixcw.us.auth0.com` — must end in `.com`, not `.col`.)

### Optional: HTTPS / Universal Links

Only if you want `useHTTPS: true` (no “Open in App” prompt):

1. Xcode → **Runner** → **Signing & Capabilities** → **Associated Domains** → `webcredentials:YOUR_DOMAIN`
2. Auth0 → **Advanced** → **Device Settings** → Apple Team ID + bundle ID (`com.shubhamambastha.expensetracker` on iOS)
3. Run with `--dart-define=AUTH0_USE_HTTPS=true`

Without step 1, HTTPS login fails with “not associated with domain”.

## 5. Verify JWT

After login, decode the ID token at [jwt.io](https://jwt.io) and confirm:

- `sub` — Auth0 user id (stored as `user_id` in Postgres)
- `role` — must be `authenticated`

## Fix: `PGRST301` / “No suitable key was found to decode the JWT”

Login succeeds in the app, but sync calls fail with **401** and `PGRST301`. That means Supabase received your Auth0 **ID token** but is still trying to verify it with **Supabase Auth keys** instead of **Auth0’s public keys**.

Checklist (all required):

1. **Supabase Dashboard** → **Authentication** → **Third-Party Auth** → add **Auth0**
   - Use your Auth0 **Tenant ID** (from Auth0 → Settings → General, or the subdomain before `.auth0.com`)
   - Add **Tenant region** if your tenant is not US (e.g. EU, AU)
   - Save and wait a minute for config to propagate

2. **Auth0 Action** on **Login / Post Login** (deployed and added to the flow):
   ```javascript
   exports.onExecutePostLogin = async (event, api) => {
     api.idToken.setCustomClaim('role', 'authenticated');
   };
   ```

3. **Verify the token** after login: paste the ID token into [jwt.io](https://jwt.io) (header only is enough). You should see:
   - `alg`: `RS256` (not `HS256` — unsupported for third-party Auth0)
   - payload includes `"role": "authenticated"`

4. **`config.dev.json`** must use the **same** Supabase project where you enabled Auth0 integration:
   - `SUPABASE_URL` = `https://<project-ref>.supabase.co`
   - `SUPABASE_ANON_KEY` = that project’s anon / publishable key (Project Settings → API)

5. **Sign out and sign in again** after changing dashboard settings so a fresh ID token is issued.

The Flutter app already sends `credentials.idToken` to Supabase ([Supabase Auth0 guide](https://supabase.com/docs/guides/auth/third-party/auth0)); no extra deploy or app URL is required for local runs.

## References

- [Auth0 Flutter quickstart](https://auth0.com/docs/quickstart/native/flutter)
- [Supabase third-party Auth0](https://supabase.com/docs/guides/auth/third-party/auth0)
