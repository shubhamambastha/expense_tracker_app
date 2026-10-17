# Jebbo

Jebbo — a Flutter expense tracker with Supabase Auth login — email + password, Google, Apple (or an on-device guest mode), a Node REST API (`backend/`), and Supabase Postgres behind it. Light/dark theme with a user-picked accent, no state-management framework (`ChangeNotifier`/`ValueNotifier` singletons + local `setState`).

Full docs live in `docs/` — read them before making non-trivial changes:

| Doc | Read this for |
| --- | --- |
| [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md) | App structure, services, navigation, state management, layer rules |
| [docs/DESIGN.md](./docs/DESIGN.md) | Design tokens, shared UI primitives, motion, component catalog |
| [docs/BACKEND.md](./docs/BACKEND.md) | Node API: endpoints, auth flow, run/deploy, trade-offs |
| [docs/DATABASE_SCHEMA.md](./docs/DATABASE_SCHEMA.md) | Postgres schema, ER diagram, migration order |
| [docs/FEATURES.md](./docs/FEATURES.md) | Business/validation rules per feature, cited to the code |
| [docs/BACKLOG.md](./docs/BACKLOG.md) | Known gaps, half-finished features, structural debt |
| [docs/RUNBOOK.md](./docs/RUNBOOK.md) | Incidents: where the logs are, symptom → cause → fix, rollback |
| [docs/DEPLOY_CHECKLIST.md](./docs/DEPLOY_CHECKLIST.md) | Production-readiness checklist, incl. the Supabase Auth cutover order (B4) |
| [docs/PRIVACY_POLICY.md](./docs/PRIVACY_POLICY.md) + [APP_PRIVACY_LABELS.md](./docs/APP_PRIVACY_LABELS.md) + [TERMS.md](./docs/TERMS.md) | Public privacy policy, App Store / Play labels, and terms — update when adding an SDK, permission, data field, or paid feature |
| [TODOS.md](./TODOS.md) | Review follow-ups with priority/effort |
| [docs/designs/](./docs/designs/) | Point-in-time design docs (guest mode, onboarding, insight digest) |
| [docs/supabase_setup.md](./docs/supabase_setup.md) | Supabase project, auth providers (email + password, Google, Apple), RLS, CI secrets |

## Commands

```bash
# Run the app (reads config.dev.json and passes values as --dart-define)
python3 scripts/define_from_json.py config.dev.json run

# Build (any flutter subcommand works — args pass through)
python3 scripts/define_from_json.py config.dev.json build ios --release

# Lint — must stay clean before committing
flutter analyze

# Tests
flutter test

# Fetch/upgrade packages
flutter pub get

# Backend API (needs backend/.env — copy backend/.env.example)
cd backend && npm install && npm run dev
cd backend && npm test
```

There is no named router and no bundled `.env` — secrets are compile-time `--dart-define` values. Copy `config.dev.json.example` to `config.dev.json` (gitignored) and fill in `API_BASE_URL`, `SUPABASE_URL` + publishable key, and the Google client IDs before running. The app talks to Supabase **only for auth**; all data goes through the API. The service-role key lives only in `backend/.env`.

## Conventions

- **Layers**: `screens/` own navigation and orchestration; `components/` are UI-only (no direct API calls, receive callbacks); `services/` are singletons, one per backend/cross-cutting concern; `utils/` are pure functions safe to unit test without widget binding. See [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md#layer-rules) for the full rules.
- **Design tokens only** — never hardcode a hex color, radius, duration, or font in a widget. Everything comes from `lib/config/design_tokens.dart` (`AppColors`, `AppRadii`, `AppSpacing`, `AppTextStyles`, `AppShadows`, `AppDurations`, `AppCurves`). See [docs/DESIGN.md](./docs/DESIGN.md).
- **Feature flags**: compile-time toggles in `lib/config/feature_flags.dart` — no remote config. Check this file before assuming a feature is fully shipped (e.g. `transferVisible` currently hides transfers from new-entry UI; `guestModeEnabled` and `postLoginOnboardingEnabled` are kill switches).
- **Snackbars**: always go through `SnackbarHelper` (`lib/utils/snackbar_helper.dart`) — never call `ScaffoldMessenger` directly.
- **Empty/loading/error UX**: use the shared barrel `components/common/states/states.dart` rather than one-off spinners/empty widgets.
- **User scoping**: every route in `backend/src/routes/` forces `user_id = <Supabase user id (sub) from the bearer token>` on every query (mostly through the `db.js` helpers), and Supabase RLS checks the same token again. The app never sends `user_id`. If data leaks across users or comes back empty, check the token the app sends and the backend's `auth` middleware first.
- Run `flutter analyze` before considering a change done — the project is expected to stay lint-clean.

## Where things live

- `lib/screens/home/expense_home_page.dart` — the tab shell (Home · Transactions · Analytics · Settings, plus a centre Add button; Budgets is a pushed route, not a tab) and the owner of most in-memory transaction/account state.
- `lib/services/api_service.dart` — every data read/write for signed-in users (HTTP → `backend/`); guest mode branches to `GuestStore`.
- `backend/src/` — the Node API (Express 5): `middleware/auth.js` (JWT verification), `routes/<resource>.js` (routes + that table's column whitelist), `db.js` (user-scoped query helpers). Layout in [docs/BACKEND.md](./docs/BACKEND.md#code-layout).
- `lib/services/auth_service.dart` + `components/common/auth_gate.dart` — Supabase Auth/guest session and splash → login → onboarding wizard → app routing.
- `lib/services/guest_store.dart` + `guest_migration_service.dart` — guest-mode on-device storage and its replay into a real account on first sign-in.
- `sql/` — dated Supabase migration files (manually applied; see [docs/DATABASE_SCHEMA.md](./docs/DATABASE_SCHEMA.md)).
- `ios/AddExpenseWidget/` — iOS home-screen widget that deep-links into the add-expense flow.
- `templates/email/` — Supabase Auth email templates (code-only, no links), styled with the design tokens and new logo. Pasted into Supabase by hand; see its README.

## Skill routing

When the user's request matches an available skill, invoke it via the Skill tool. When in doubt, invoke the skill.

Key routing rules:
- Product ideas/brainstorming → invoke /office-hours
- Strategy/scope → invoke /plan-ceo-review
- Architecture → invoke /plan-eng-review
- Design system/plan review → invoke /design-consultation or /plan-design-review
- Full review pipeline → invoke /autoplan
- Bugs/errors → invoke /investigate
- QA/testing site behavior → invoke /qa or /qa-only
- Code review/diff check → invoke /review
- Visual polish → invoke /design-review
- Ship/deploy/PR → invoke /ship or /land-and-deploy
- Save progress → invoke /context-save
- Resume context → invoke /context-restore
- Author a backlog-ready spec/issue → invoke /spec
