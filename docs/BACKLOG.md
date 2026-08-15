# Backlog

Living list of known gaps, half-finished features, and structural debt — derived from the current codebase (feature flags, reserved-but-unused hooks, legacy adapters, test coverage) rather than aspirational planning. Update this file as items are picked up or resolved; delete a row rather than leaving it stale once it's done.

Last reviewed: 2026-08-15.

---

## In progress / flagged off

| Item | Evidence | Notes |
| --- | --- | --- |
| Transfer transactions | `FeatureFlags.transferVisible = false` in `lib/config/feature_flags.dart` | Full transfer support exists in the `Transaction` model and `TransactionKind` enum, and existing transfer rows still display/edit correctly, but the flag hides it from quick actions, the type selector, and filters for new entries. Flip the flag once the flow is validated end-to-end. |
| Biometric app-lock | `SplashBootstrapResult.requiresBiometricUnlock` field exists in `lib/services/splash_bootstrap.dart` and is computed, but no screen/gate consumes it yet | Wire a lock screen into `AuthGate` that checks this flag on resume. |
| Onboarding flow | `SplashDestination.onboarding` is a reserved enum value in `splash_bootstrap.dart`, resolved from an `onboarding_complete` local pref, but no onboarding screen exists to route to | Either build the onboarding screens or remove the reserved destination/pref key if it's no longer planned. |
| `WeekStartDay` / `FinancialYear` settings unwired | Both settings exist in `settings_preferences.dart` and their own settings-page UI, but nothing outside that file reads them | Date-preset filtering (`transaction_filter_logic.dart::dateRangeForPreset`) and transaction grouping (`transaction_grouping.dart`) hardcode Monday-start weeks and calendar-year months regardless of what the user picks. Either wire these settings into that logic or remove the UI so it stops implying it does something. See [FEATURES.md](./FEATURES.md#currency--display-settings). |

---

## Correctness risks

| Item | Evidence | Notes |
| --- | --- | --- |
| Two divergent "next due date" implementations for recurring transactions | Recurring Manager uses `recurring_management.dart::nextDueWithEvents` (honors paid/skipped/snoozed events); the transaction detail sheet and dashboard's upcoming card instead use `upcoming_payments.dart::computeNextPaymentDate`, which never looks at `recurring_events` | A schedule the user just marked "paid" or "snoozed" in the manager can still show its old due date on the dashboard/detail sheet until the underlying transaction row itself changes. Consolidate on one due-date function. See [FEATURES.md](./FEATURES.md#recurring-transactions--recurring-events). |
| Monthly-equivalent normalization formula implemented three times independently | `recurring_management.dart::monthlyEquivalent`, `analytics_aggregations.dart::_normaliseMonthly`, `financial_insights.dart::_normaliseToMonthly` all reimplement the same weekly ×4.33 / daily ×30 / quarterly ÷3 / yearly ÷12 conversion | No shared source of truth — a future change to the formula (e.g. more precise weekly multiplier) has to be made in three places or the manager, analytics, and insights will silently disagree. Extract to one util function. |

---

## Structural debt

| Item | Evidence | Notes |
| --- | --- | --- |
| `ExpenseHomePage` owns too much | `lib/screens/home/expense_home_page.dart` is ~900 lines and holds transactions/accounts state, all CRUD callbacks, and cross-tab navigation | Noted as a known trade-off in [ARCHITECTURE.md](./ARCHITECTURE.md#state-management). Extracting a dedicated controller/notifier is the natural next step before adding more tabs. |
| Legacy `expenses` table/model | `lib/models/expense.dart` plus `fetchExpenses`/`insertExpense` adapters in `lib/services/supabase_service.dart`; `sql/` still has the old `expenses` table migration | The app reads/writes `transactions` exclusively now. Confirm nothing still calls the legacy adapters, then remove the model, adapters, and (separately, carefully) plan a data migration off the old table. |
| No named router | No `go_router` or routes table — navigation is ad hoc `Navigator.push` + tab index | Fine for current scope; blocks deep-linking to arbitrary screens and web URL parity. Listed as a future direction in [ARCHITECTURE.md](./ARCHITECTURE.md#future-improvements). |
| No offline cache | Every load hits Supabase directly; no local persistence layer beyond `shared_preferences` for small settings | A Drift/Isar cache with sync would improve cold-start and flaky-network UX. |

---

## Test coverage

| Item | Evidence | Notes |
| --- | --- | --- |
| Near-zero test coverage | `test/` has 2 files: `widget_test.dart` (pumps a hardcoded `MaterialApp` stub, not the real app) and `app_launch_intent_test.dart` | No coverage for `SupabaseService`, aggregation utils (`dashboard_aggregations.dart`, `analytics_aggregations.dart`, `financial_insights.dart`), or transaction/recurring/account flows. These are pure-logic files and cheap to test first. |

---

## Smaller / opportunistic

| Item | Evidence | Notes |
| --- | --- | --- |
| Localization | Only English strings, hardcoded inline (no ARB files or `flutter gen-l10n` setup) | Fine for single-market MVP; flagged in ARCHITECTURE.md as a future direction. |
| Legacy chip selectors | `AccountChipsSelector` and `IncomeCategoryPillsSelector` are marked "legacy horizontal chips" in [DESIGN.md](./DESIGN.md#transaction-form--list) with no listed replacement in progress | Confirm whether these are still the intended pattern or should be consolidated with the newer pill/section components used elsewhere in the add-transaction flow. |

---

## Related docs

- [ARCHITECTURE.md](./ARCHITECTURE.md) — see "Future improvements" for longer-horizon architectural direction
- [DESIGN.md](./DESIGN.md) — component catalog referenced above
- [FEATURES.md](./FEATURES.md) — feature behavior/rules catalog; source of the correctness-risk items above
