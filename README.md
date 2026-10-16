# expense_tracker_app

Flutter expense tracker with Supabase Auth login — email + password, Google, Apple (or an on-device guest mode) and a Node REST API (`backend/`) over Supabase Postgres.

## Documentation

| Doc | Description |
| --- | --- |
| [CLAUDE.md](./CLAUDE.md) | Project instructions for AI coding agents — conventions, commands, doc index |
| [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md) | App structure, services, navigation, state |
| [docs/DESIGN.md](./docs/DESIGN.md) | Design tokens, shared UI primitives, motion |
| [docs/DATABASE_SCHEMA.md](./docs/DATABASE_SCHEMA.md) | Postgres schema mind map, ER diagram, migrations |
| [docs/FEATURES.md](./docs/FEATURES.md) | Feature catalog with business/validation rules |
| [docs/BACKLOG.md](./docs/BACKLOG.md) | Known gaps, flagged-off features, structural debt |
| [docs/BACKEND.md](./docs/BACKEND.md) | Node API: endpoints, run locally, deploy |
| [docs/supabase_setup.md](./docs/supabase_setup.md) | Supabase project, auth providers (email + password, Google, Apple), RLS, CI secrets |
| [docs/RUNBOOK.md](./docs/RUNBOOK.md) | Incidents: where the logs are, symptom → cause → fix, rollback |
| [docs/DEPLOY_CHECKLIST.md](./docs/DEPLOY_CHECKLIST.md) | Production-readiness checklist, incl. the Supabase Auth cutover order (B4) |
| [TODOS.md](./TODOS.md) | Review follow-ups with priority/effort |
| [docs/designs/](./docs/designs/) | Point-in-time design docs (guest mode, onboarding, insight digest) |

## Getting started

1. Copy `config.dev.json.example` to `config.dev.json` and fill in keys.
2. Follow [docs/supabase_setup.md](./docs/supabase_setup.md) (database, auth providers, CI).
3. Start the API the app talks to (`backend/`), see [docs/BACKEND.md](./docs/BACKEND.md#run-locally).
4. Run the app:

```bash
python3 scripts/define_from_json.py config.dev.json run
```

## Building an Android APK

Both builds go through `scripts/define_from_json.py`, which passes the config values as `--dart-define`. APKs are written to `build/app/outputs/flutter-apk/`.

### Debug APK (testing on your own devices)

```bash
python3 scripts/define_from_json.py config.dev.json build apk --debug
```

- Output: `app-debug.apk`. Install it with `adb install -r build/app/outputs/flutter-apk/app-debug.apk`.
- Signed with your machine's debug key (`~/.android/debug.keystore`). No setup needed.
- `http://` is allowed (only the debug manifest permits cleartext). On a phone, `localhost` points at the phone itself. Set `API_BASE_URL` to your Mac's LAN IP (e.g. `http://192.168.1.20:3000`), or to `http://10.0.2.2:3000` on the emulator.
- Google Sign-In only works if the debug SHA-1 is registered on the Android OAuth client. Get it from `cd android && ./gradlew signingReport`.
- Large and slow (JIT, no tree-shaking). Never distribute it.

### Release APK (production)

One-time setup:

1. Create an upload keystore outside the repo and back it up. If you lose it, you can't publish updates.
   ```bash
   keytool -genkey -v -keystore ~/keys/jebbo-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Create `android/key.properties` (gitignored):
   ```
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=/absolute/path/to/jebbo-upload.jks
   ```
   Without this file, release builds fall back to the debug key and Gradle logs a warning. The Play Store rejects those builds.
3. Copy `config.dev.json.example` to `config.prod.json` (gitignored) with production values. `API_BASE_URL` must be `https://`, because release builds refuse to start otherwise.
4. Add the release SHA-1 (from `./gradlew signingReport`) to the Google Android OAuth client. With Play App Signing, also add Play's app-signing SHA-1. Otherwise Google login fails.

For each release, bump `version` in `pubspec.yaml` (the `+N` build number must increase every upload), then build:

```bash
python3 scripts/define_from_json.py config.prod.json build apk --release --obfuscate --split-debug-info=build/symbols --split-per-abi
```

- Output: one APK per ABI (`app-arm64-v8a-release.apk` and others). Keep `build/symbols`. You need it to read stack traces from obfuscated builds.
- For the Play Store, build an app bundle instead (`build appbundle` with the same flags, minus `--split-per-abi`).
- Check the signature. The output should show your upload key, not "Android Debug":
  `apksigner verify --print-certs build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
