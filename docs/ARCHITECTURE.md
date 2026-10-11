# Expense Tracker App — Architecture

## Overview

Flutter expense tracker with Auth0 login, a Node REST API in front of Supabase Postgres ([BACKEND.md](./BACKEND.md)), and a component-based UI. The app is organized into thin screens, reusable components, singleton services, and pure utils — no global state-management framework; session-scoped data lives in `ChangeNotifier` / `ValueNotifier` singletons, and tab-level data is owned by `ExpenseHomePage`.

Visual conventions live in [DESIGN.md](./DESIGN.md). Database schema (mind map): [DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md). Backend API: [BACKEND.md](./BACKEND.md). Setup guides: [auth0_setup.md](./auth0_setup.md), [supabase_setup.md](./supabase_setup.md).

---

## High-level flow

```mermaid
flowchart TD
  main[main.dart] --> init[Parallel init: ApiService/Auth0, CurrencySettings, SettingsPreferences]
  init --> app[ExpenseTrackerApp]
  app --> gate[AuthGate]
  gate --> splash[SplashScreen + SplashBootstrap]
  gate --> login[LoginPage: Auth0 or Continue as guest]
  gate --> wizard[OnboardingWizardPage, first run only]
  gate --> home[ExpenseHomePage tab shell]
  home --> tabs[Home · Transactions · Analytics · Settings]
  home --> push[Push routes: add transaction, accounts, recurring, budgets]
  services[Services layer] --> api[ApiService]
  services --> auth[AuthService]
  api -->|REST + Bearer ID token| node[backend/ Node API]
  api -->|guest mode| guest[(GuestStore, on-device)]
  node --> db[(Supabase Postgres)]
  auth --> auth0[Auth0 Universal Login]
  auth -->|ID token| api
```

---

## Bootstrap

`main.dart` initializes the app in parallel, then mounts `AuthGate`:

1. `ApiService.init()` — checks `API_BASE_URL` and initializes `AuthService` (Auth0)
2. `CurrencySettings.instance.load()` — local currency preference
3. `SettingsPreferences.instance.load()` — local user settings cache
4. `DeepLinkService.instance.start()` — widget / app-link intents (non-blocking)

On failure, `ErrorApp` is shown instead of the main app.

`ExpenseTrackerApp` wraps `MaterialApp` in a `ListenableBuilder` over global preference notifiers (`CurrencySettings`, `CategoryCatalog`, `SettingsPreferences`) so theme-adjacent rebuilds propagate when catalogs change.

Compile-time secrets come from `--dart-define` (see `config.dev.json.example` and `lib/utils/app_config.dart`):

| Define | Purpose |
| --- | --- |
| `API_BASE_URL` | Node API base URL, e.g. `http://localhost:3000` (see [BACKEND.md](./BACKEND.md#run-locally)) |
| `AUTH0_DOMAIN` | Auth0 tenant domain |
| `AUTH0_CLIENT_ID` | Auth0 native app client ID |
| `AUTH0_CALLBACK_SCHEME` | iOS custom-scheme callback (optional) |
| `AUTH0_USE_HTTPS` | Use HTTPS app links on iOS (optional) |

---

## Authentication

**Auth0** handles login. `ApiService` sends the Auth0 ID token as `Authorization: Bearer …` on every request. The Node API verifies it, derives `user_id` from `sub`, and forwards the same token to Supabase so RLS still applies. See [BACKEND.md](./BACKEND.md).

**Guest mode** ("Continue as guest", behind `FeatureFlags.guestModeEnabled`) skips Auth0. `AuthService.isGuest` is persisted, and every `ApiService` method branches to `GuestStore` (SharedPreferences, no network) when it's true. On the first real sign-in with guest data present, `GuestMigrationService` offers to replay it into the account (all-or-nothing, rolls back on failure); declined data stays local and can be imported later from Settings → Data & Privacy. Design: [designs/guest-mode.md](./designs/guest-mode.md).

| Piece | Location | Role |
| --- | --- | --- |
| `AuthService` | `services/auth_service.dart` | Auth0 SDK, credential storage, `AppSession` notifier |
| `AuthGate` | `components/common/auth_gate.dart` | Routes splash → login → onboarding wizard → app based on session / guest flag |
| `SplashBootstrap` | `services/splash_bootstrap.dart` | Offline-first startup: restore session, sync prefs, pick destination |
| `LoginPage` | `screens/auth/login_page.dart` | Auth0 Universal Login entry + "Continue as guest" |
| `OnboardingWizardPage` | `screens/onboarding/onboarding_wizard_page.dart` | First-run wizard: name → currency → budget → accounts → income → recurring. Shown once per account (`OnboardingWizardStatus`; `user_settings.onboarding_completed_at` remotely) |
| `auth` middleware | `backend/src/app.js` | Verifies the JWT and scopes every query to Auth0 `sub` |

On sign-in, `AuthGate` syncs user-scoped singletons (`CategoryCatalog`, `IncomeCategoryCatalog`, `CategoryBudgetService`, `CurrencySettings`, `SettingsPreferences`). On sign-out, each calls `onSignedOut()` to clear in-memory state.

`SplashBootstrap` still has a separate, unused pre-login `SplashDestination.onboarding` (+ `onboarding_complete` pref); `AuthGate` maps it to login. It is not the post-login wizard, see [BACKLOG.md](./BACKLOG.md).

---

## Navigation

There is no named router (`go_router` / routes table). Navigation uses two patterns:

### Tab shell (`ExpenseHomePage`)

Four bottom-nav tabs: **Home (0) · Transactions (1) · Analytics (2) · Settings (3)**, plus a raised centre Add button (not a tab index) that opens `AddTransactionPage` for an expense. Tab bodies swap via `AnimatedSwitcher`.

Tab content is composed inline:

| Index | Content | Primary file |
| --- | --- | --- |
| 0 | Dashboard | `components/home/home_content.dart` |
| 1 | Transaction list | `components/home/transactions_content.dart` |
| 2 | Analytics | `screens/analytics/analytics_page.dart` |
| 3 | Settings hub | `screens/settings/settings_page.dart` |

Budgets is no longer a tab. `_openBudgetSettings()` pushes a private `_BudgetsPage` (in `expense_home_page.dart`) that wraps `BudgetsAndSpendingContent` from `screens/settings/sections/budgets_and_spending_page.dart`. Home, Analytics and Settings → Money all open it.

### Push routes

Full-screen flows use `Navigator.push` from the home shell or settings:

- `screens/transaction/add_transaction_page.dart` — create / edit transactions
- `screens/accounts/` — list, detail, add/edit bank/credit/wallet accounts
- `screens/recurring/recurring_payments_page.dart` — subscriptions, EMIs, upcoming timeline
- Budgets — see above
- `screens/settings/sections/` — settings sub-pages: Appearance, Money, Categories, Data & Privacy, Help Center, About, Edit Profile

Sheets and dialogs (`showModalBottomSheet`, custom overlays) live under `components/dialogs/` and feature folders (e.g. `transaction_detail_sheet.dart`).

---

## Project structure

```
lib/
├── main.dart
├── config/
│   ├── design_tokens.dart          # Colors, spacing, typography tokens
│   ├── theme.dart                  # AppTheme.darkTheme / lightTheme (Material 3)
│   ├── feature_flags.dart          # Compile-time UI toggles (see Feature flags)
│   └── app_info.dart               # App version + support email (placeholder, see TODOS.md)
├── models/                         # Domain types & API (snake_case row) mappers
├── services/                       # Singletons: auth, sync, preferences
├── screens/                        # Full pages & navigation owners
├── components/                     # Reusable UI by feature area
└── utils/                          # Pure helpers, aggregations, validators

backend/                            # Node REST API (see BACKEND.md)
sql/                                # Supabase migrations (see DATABASE_SCHEMA.md)
docs/                               # Architecture, backend, schema, design & setup docs
ios/AddExpenseWidget/               # iOS home-screen widget (deep link → add expense)
```

### `lib/models/`

| File | Purpose |
| --- | --- |
| `transaction.dart` | Primary money event (`expense` / `income` / `transfer`), recurrence fields |
| `transaction_draft.dart` | Mutable form state for add/edit flows |
| `transaction_filters.dart` | List filter model |
| `account.dart` | Bank, credit card, wallet accounts |
| `expense.dart` | `AccountType` enum + labels (legacy file name; the `Expense` model is gone) |
| `expense_category.dart` / `income_category.dart` | User category rows |
| `category_budget.dart` | Per-category monthly budgets |
| `recurring_event.dart` | Standalone recurring events table |
| `user_settings.dart` | Remote user preferences row |
| `app_session.dart` | Auth0 session snapshot |

### `lib/services/`

| Service | Pattern | Purpose |
| --- | --- | --- |
| `ApiService` | Static methods | All data CRUD over HTTP to `backend/` (guest → `GuestStore`) |
| `AuthService` | Singleton + `ValueNotifier` | Auth0 session + persisted `isGuest` flag |
| `GuestStore` | Singleton | Guest-mode mirror of every table in SharedPreferences (negative local ids) |
| `GuestMigrationService` | Singleton | Replays guest data into a real account, with rollback |
| `SplashBootstrap` | Singleton | Startup orchestration |
| `CategoryCatalog` | Singleton + `ChangeNotifier` | Expense categories (local + remote) |
| `IncomeCategoryCatalog` | Singleton + `ChangeNotifier` | Income categories |
| `CategorySyncCache` | Generic helper | Shared remote-first load / local fallback / single-flight sync for both catalogs |
| `CategoryBudgetService` | Singleton + `ChangeNotifier` | Category budgets |
| `CurrencySettings` | Singleton + `ChangeNotifier` | Display currency |
| `SettingsPreferences` | Singleton + `ChangeNotifier` | App preferences (theme, accent, monthly limit, toggles), synced to `user_settings.preferences` |
| `OnboardingWizardStatus` | Singleton | Whether the post-login wizard is done (local flag first, then remote column) |
| `OnboardingAnalytics` | Singleton | Local-only wizard counters, never sent anywhere |
| `TransactionListPreferences` | Singleton | Transactions tab sort/filter prefs |
| `DeepLinkService` | Singleton | App link listener |
| `SplashBootstrap` / `TransactionListPreferences` | Singleton | Startup orchestration / Transactions tab sort & filter prefs |
| `AppLaunchIntentHolder` | Singleton + `ValueNotifier` | Parsed widget intents |

### `lib/screens/`

| Folder | Screens |
| --- | --- |
| `auth/` | `login_page.dart`, `splash_screen.dart` |
| `onboarding/` | `onboarding_wizard_page.dart` — 6-step first-run wizard |
| `home/` | `expense_home_page.dart` — main tab shell & data owner |
| `transaction/` | `add_transaction_page.dart` |
| `accounts/` | List, detail, credit detail, add/edit |
| `analytics/` | `analytics_page.dart` |
| `recurring/` | `recurring_payments_page.dart` |
| `settings/` | Hub + `sections/` sub-pages |

### `lib/components/`

Feature-grouped reusable widgets. Screens compose these; they do not call `ApiService` directly (callbacks / data passed from parent).

| Folder | Responsibility |
| --- | --- |
| `common/` | `auth_gate`, `error_app`, `compact_header`, `subscription_badge`, `states/` (empty/loading/error UX) |
| `home/` | Dashboard + transactions tab content |
| `home/dashboard/` | Hero card, recent transactions, quick actions, budget sheet |
| `transaction/` | Add form fields, list item, detail sheet + sections |
| `accounts/` | Account cards, forms, credit sections |
| `analytics/` | Analytics sections + chart widgets |
| `recurring/` | Subscription/EMI cards, timeline, add sheet |
| `settings/` | Settings rows, sections, subpage scaffold |
| `profile/` | Profile edit widgets |
| `onboarding/` | Wizard step widgets + shared step scaffold / progress header |
| `auth/` | Login form |
| `dialogs/` | Shared modals and confirmation sheets |

### `lib/utils/`

Pure functions and small helpers — no Flutter widget trees except where UI-adjacent (e.g. `snackbar_helper.dart`).

| Area | Files |
| --- | --- |
| Config | `app_config.dart`, `constants.dart`, `auth0_urls.dart` |
| Validation | `validators.dart` |
| UX | `snackbar_helper.dart`, `category_style.dart` |
| Aggregations | `dashboard_aggregations.dart`, `analytics_aggregations.dart`, `financial_insights.dart` |
| Domain | `recurring_management.dart`, `upcoming_payments.dart`, `account_management.dart`, `transaction_filter_logic.dart`, `transaction_grouping.dart`, `transaction_subtype_helpers.dart`, `income_flow_helpers.dart`, `recurrence_normalization.dart`, `emi_schedule_helpers.dart`, `subscription_catalog.dart` |
| Settings & data | `data_export.dart` (CSV), `account_deletion_request.dart` (mailto), `onboarding_locale_currency.dart` |
| Formatting | `transaction_date_format.dart`, `profile_identity.dart` |

---

## Feature flags

`lib/config/feature_flags.dart` holds compile-time UI toggles — no remote config, just a static class flipped in source. Current flags:

| Flag | Default | Effect |
| --- | --- | --- |
| `FeatureFlags.transferVisible` | `false` | Hides `transfer` from the quick actions, type selector, and filters. Existing transfer transactions still display/edit normally; `normalizeKind()` downgrades new transfers to `expense`. |
| `FeatureFlags.guestModeEnabled` | `true` | Shows "Continue as guest" on the login screen. Kill switch for the guest data path. |
| `FeatureFlags.postLoginOnboardingEnabled` | `true` | When `false`, `AuthGate` skips the onboarding wizard and every user goes straight to the dashboard. |

Screens read flags directly (e.g. `expense_home_page.dart` guards the transfer quick action) rather than threading a config object through the widget tree. Add new flags as additional static `const bool` fields plus any derived helper methods, following the same pattern.

---

## Data layer

### Supabase tables

Migrations are dated SQL files in `sql/`, applied manually to Supabase. For the full mind-map view (relationships, enums, migration order), see [DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md). Core tables:

| Table | Model | Notes |
| --- | --- | --- |
| `transactions` | `Transaction` | Unified expenses, income, transfers; recurrence on same row |
| `accounts` | `Account` | Bank, credit, wallet; opening balance + metadata |
| `expense_categories` | `ExpenseCategory` | User-defined with icon keys |
| `income_categories` | `IncomeCategory` | Same pattern for income |
| `category_budgets` | `CategoryBudget` | Monthly limits per category |
| `recurring_events` | `RecurringEvent` | Supplemental recurring metadata |
| `user_settings` | `UserSettings` | Currency, `preferences` jsonb, `onboarding_completed_at` |

Legacy `expenses` table SQL remains for reference; the app reads/writes `transactions`.

### `ApiService` surface

Each method maps to one REST endpoint. The full table is in [BACKEND.md](./BACKEND.md#endpoints).

Grouped responsibilities:

- **Transactions** — `fetchTransactions`, `insertTransaction`, `updateTransaction`, `deleteTransaction`, pause/close recurring
- **Accounts** — CRUD + archive
- **Categories** — fetch, seed defaults, insert/delete (expense + income)
- **Budgets** — fetch, upsert, delete
- **Recurring events** — fetch, insert, delete
- **User settings** — fetch, upsert

The app never sends `user_id`. The backend sets it from the verified token.

---

## State management

No Provider / Riverpod / Bloc. Current approach:

| Scope | Owner | Mechanism |
| --- | --- | --- |
| Auth session | `AuthService.session` | `ValueNotifier<AppSession?>` |
| Global prefs / catalogs | Service singletons | `ChangeNotifier` + `ListenableBuilder` in `main.dart` |
| Tab data (transactions, accounts) | `ExpenseHomePage` | `StatefulWidget` + `setState`, refreshed via `_loadTransactions` / `_refreshDashboard` |
| Feature sub-screens | Individual screens | Local state; mutate via `ApiService`, then callback to parent or pop |
| Forms | Page state / `TransactionDraft` | Passed into components as immutable snapshots + callbacks |

This keeps dependencies explicit. Trade-off: `ExpenseHomePage` is large and owns most synced list state; extracting a dedicated dashboard controller would be a natural next step.

---

## Deep links & iOS widget

`DeepLinkService` listens for app links and writes parsed intents to `AppLaunchIntentHolder`. `ExpenseHomePage` polls/consumes intents after load to open the add-expense flow (used by the iOS `AddExpenseWidget`).

---

## Layer rules

### Screens
- Own navigation and orchestration
- Fetch/mutate via `ApiService` (or delegate to a service singleton)
- Pass data + callbacks into components

### Components
- Single UI concern; stateless when possible
- No direct `ApiService` calls — receive `onSave`, `onDelete`, etc.
- Import design tokens, not hardcoded colors

### Services
- One backend or cross-cutting concern per file
- Singleton `.instance` for app-wide lifecycle
- `onSignedOut()` / `syncForUser()` hooks for auth transitions

### Utils
- Pure logic, formatting, aggregations
- Safe to unit test without widget binding

---

## Dependency sketch

```
main.dart
├── config/theme.dart
├── services/api_service.dart → auth_service.dart, models/* → HTTP → backend/
├── services/currency_settings.dart
├── services/settings_preferences.dart
├── services/deep_link_service.dart
└── components/common/auth_gate.dart
    ├── services/splash_bootstrap.dart
    ├── screens/auth/splash_screen.dart
    ├── screens/auth/login_page.dart
    │   └── components/auth/login_form.dart
    ├── screens/onboarding/onboarding_wizard_page.dart
    └── screens/home/expense_home_page.dart
        ├── services/api_service.dart
        ├── components/home/home_content.dart
        ├── components/home/transactions_content.dart
        ├── screens/analytics/analytics_page.dart
        ├── screens/settings/settings_page.dart
        │   └── screens/settings/sections/*
        └── (push) screens/transaction, accounts, recurring
```

---

## Adding features

### New tab or top-level area
1. Add screen under `lib/screens/{feature}/`
2. Build UI from `lib/components/{feature}/`
3. Wire into `ExpenseHomePage` (new tab index) or push from an existing screen

### New settings section
1. Create page in `screens/settings/sections/`
2. Wrap with `SettingsSubpageScaffold`
3. Compose `SettingsSection` + tile widgets
4. Persist via `SettingsPreferences`, `CategoryCatalog`, or `ApiService` as appropriate

### New database entity
1. Add migration in `sql/` (with RLS on `user_id`)
2. Add `backend/src/routes/<resource>.js` (routes + column whitelist) and mount it in `backend/src/routes/index.js`
3. Add model in `lib/models/`
4. Add methods to `ApiService` (and `GuestStore` for guest mode)
5. Optionally add a `ChangeNotifier` singleton if the data is user-global and cached

### New reusable widget
1. Place in the matching `components/{feature}/` folder
2. Accept data + callbacks via constructor
3. Follow [DESIGN.md](./DESIGN.md) tokens and shared primitives (`states.dart`, section cards)

---

## Debugging guide

| Symptom | Start here |
| --- | --- |
| App won't start / config error | `main.dart`, `app_config.dart`, `--dart-define` values |
| Stuck on splash | `splash_bootstrap.dart`, `auth_service.dart` |
| Login / session issues | `auth_gate.dart`, `auth_service.dart`, Auth0 callback config |
| Onboarding wizard shows again / never shows | `onboarding_wizard_status.dart`, `user_settings.onboarding_completed_at`, `FeatureFlags.postLoginOnboardingEnabled` |
| Guest data missing after sign-in | `guest_migration_service.dart`, Settings → Data & Privacy guest-data section |
| Data not saving | `api_service.dart` (`ApiException` status), backend logs, Supabase RLS policies |
| Wrong user scope | `auth` middleware in `backend/src/middleware/auth.js` (`user_id` := token `sub`) and Supabase RLS policies |
| Dashboard numbers wrong | `utils/dashboard_aggregations.dart`, `financial_insights.dart` |
| Analytics charts empty | `utils/analytics_aggregations.dart`, `analytics_content.dart` |
| Recurring timeline | `utils/upcoming_payments.dart`, `recurring_management.dart` |
| Widget deep link | `deep_link_service.dart`, `app_launch_intent.dart`, `expense_home_page.dart` |
| Visual inconsistency | [DESIGN.md](./DESIGN.md), `design_tokens.dart` |
| Feature hidden/showing unexpectedly | `config/feature_flags.dart` |

---

## Performance notes

- Lists use `ListView` / `ListView.separated` with keys where items mutate
- `const` constructors used where possible in leaf components
- Category/catalog sync is deduplicated (`_syncInFlight` guards in catalogs)
- Splash bootstrap bounds network work; deferred sync continues after navigation
- Tab switch animates with `AnimatedSwitcher` — bodies rebuild on index change

---

## Future improvements

| Area | Direction |
| --- | --- |
| State management | Extract `ExpenseHomePage` data into a dedicated notifier or lightweight store |
| Routing | Adopt `go_router` for deep links and web URL parity |
| Testing | Mirror `lib/` structure under `test/`; mock `ApiService` |
| Localization | `flutter gen-l10n` + ARB files |
| Offline | Local cache layer (Drift/isar) synced through the API |
| Biometrics | Hook planned in `SplashBootstrapResult.requiresBiometricUnlock` |

---

## Related docs

- [DESIGN.md](./DESIGN.md) — design tokens, shared UI primitives, motion
- [DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md) — Postgres tables, ER diagram, migration order
- [BACKEND.md](./BACKEND.md) — Node API endpoints, auth flow, run/deploy
- [auth0_setup.md](./auth0_setup.md) — Auth0 tenant & callback setup
- [supabase_setup.md](./supabase_setup.md) — Supabase project & RLS
- [config.dev.json.example](../config.dev.json.example) — local `--dart-define` template
