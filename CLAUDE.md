# expense_tracker_app

Flutter expense tracker with Auth0 login and Supabase persistence. Dark-theme-only, no state-management framework (`ChangeNotifier`/`ValueNotifier` singletons + local `setState`).

Full docs live in `docs/` — read them before making non-trivial changes:

| Doc | Read this for |
| --- | --- |
| [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md) | App structure, services, navigation, state management, layer rules |
| [docs/DESIGN.md](./docs/DESIGN.md) | Design tokens, shared UI primitives, motion, component catalog |
| [docs/DATABASE_SCHEMA.md](./docs/DATABASE_SCHEMA.md) | Postgres schema, ER diagram, migration order |
| [docs/BACKLOG.md](./docs/BACKLOG.md) | Known gaps, half-finished features, next-up work |
| [docs/auth0_setup.md](./docs/auth0_setup.md) | Auth0 tenant & callback setup |
| [docs/supabase_setup.md](./docs/supabase_setup.md) | Supabase project, RLS, CI secrets |

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
```

There is no named router and no bundled `.env` — secrets are compile-time `--dart-define` values. Copy `config.dev.json.example` to `config.dev.json` (gitignored) and fill in Supabase/Auth0 keys before running.

## Conventions

- **Layers**: `screens/` own navigation and orchestration; `components/` are UI-only (no direct Supabase calls, receive callbacks); `services/` are singletons, one per backend/cross-cutting concern; `utils/` are pure functions safe to unit test without widget binding. See [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md#layer-rules) for the full rules.
- **Design tokens only** — never hardcode a hex color, radius, duration, or font in a widget. Everything comes from `lib/config/design_tokens.dart` (`AppColors`, `AppRadii`, `AppSpacing`, `AppTextStyles`, `AppShadows`, `AppDurations`, `AppCurves`). See [docs/DESIGN.md](./docs/DESIGN.md).
- **Feature flags**: compile-time toggles in `lib/config/feature_flags.dart` — no remote config. Check this file before assuming a feature is fully shipped (e.g. `transferVisible` currently hides transfers from new-entry UI).
- **Snackbars**: always go through `SnackbarHelper` (`lib/utils/snackbar_helper.dart`) — never call `ScaffoldMessenger` directly.
- **Empty/loading/error UX**: use the shared barrel `components/common/states/states.dart` rather than one-off spinners/empty widgets.
- **User scoping**: every Supabase write/read is scoped by Auth0 `sub` via `SupabaseService.requireUserId()`. If data leaks across users or comes back empty, check this first.
- Run `flutter analyze` before considering a change done — the project is expected to stay lint-clean.

## Where things live

- `lib/screens/home/expense_home_page.dart` — the tab shell (Home · Transactions · Analytics · Budgets · Settings, plus a centre FAB for Add Transaction) and the owner of most in-memory transaction/account state.
- `lib/services/supabase_service.dart` — all Postgres CRUD.
- `lib/services/auth_service.dart` + `components/common/auth_gate.dart` — Auth0 session and splash→login→app routing.
- `sql/` — dated Supabase migration files (manually applied; see [docs/DATABASE_SCHEMA.md](./docs/DATABASE_SCHEMA.md)).
- `ios/AddExpenseWidget/` — iOS home-screen widget that deep-links into the add-expense flow.

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
