# Backlog

Living list of known gaps, half-finished features, and structural debt — derived from the current codebase (feature flags, reserved-but-unused hooks, legacy adapters, test coverage) rather than aspirational planning. Update this file as items are picked up or resolved; delete a row rather than leaving it stale once it's done.

Last reviewed: 2026-08-19.

---

## In progress / flagged off

| Item | Evidence | Notes |
| --- | --- | --- |
| Transfer transactions | `FeatureFlags.transferVisible = false` in `lib/config/feature_flags.dart` | Full transfer support exists in the `Transaction` model and `TransactionKind` enum, and existing transfer rows still display/edit correctly, but the flag hides it from quick actions, the type selector, and filters for new entries. Flip the flag once the flow is validated end-to-end. |
| Biometric app-lock | `SplashBootstrapResult.requiresBiometricUnlock` field exists in `lib/services/splash_bootstrap.dart` and is computed, but no screen/gate consumes it yet | Wire a lock screen into `AuthGate` that checks this flag on resume. |
| Onboarding flow | `SplashDestination.onboarding` is a reserved enum value in `splash_bootstrap.dart`, resolved from an `onboarding_complete` local pref, but no onboarding screen exists to route to | Either build the onboarding screens or remove the reserved destination/pref key if it's no longer planned. |
| `WeekStartDay` / `FinancialYear` settings unwired | Both settings exist in `settings_preferences.dart` and their own settings-page UI, but nothing outside that file reads them | Date-preset filtering (`transaction_filter_logic.dart::dateRangeForPreset`) and transaction grouping (`transaction_grouping.dart`) hardcode Monday-start weeks and calendar-year months regardless of what the user picks. Either wire these settings into that logic or remove the UI so it stops implying it does something. See [FEATURES.md](./FEATURES.md#currency--display-settings). |
| Add Transaction → Advanced: Recent suggestions | Removed 2026-08-18 from `TransactionAdvancedSection` (`lib/components/transaction/transaction_advanced_section.dart`); was `RecentSuggestionsSection` (now-deleted `lib/components/transaction/recent_suggestions_section.dart`), tap-to-autofill merchant/category/account/amount from the 5 most recent unique merchants | `RecentSuggestion` model and the expense-side `_buildRecentSuggestions()` builder are gone from `expense_home_page.dart` too. Note: the income-side `recentIncomeSuggestions` data path was **kept** — it still drives the Salary autofill in `add_transaction_page.dart::_applySalaryAutofillIfNeeded` — so re-adding this only needs a UI row wired back to that existing data, not new plumbing. |
| Add Transaction → Advanced: Quick-parse ("AI text") entry | Removed 2026-08-18; was `QuickAiInput` (now-deleted `lib/components/transaction/quick_ai_input.dart`) — free-text row like `240 swiggy using hdfc` parsed into amount/merchant/account/category | The regex-based `_QuickParser`/`_QuickParseResult` in `add_transaction_page.dart` was deleted alongside it (not reused elsewhere). Re-implementing later is a good place to swap the naive regex parser for an actual LLM-backed one, per the "AI text" framing. |
| Add Transaction → Advanced: Attachments | Removed 2026-08-18; was a disabled "Soon" placeholder row (`_SoonRow`) in `TransactionAdvancedSection` | No backing model/storage exists yet — needs a Supabase storage bucket + column on `transactions` before UI is worth adding back. |
| Add Transaction → Advanced: Custom Metadata | Removed 2026-08-18; was a disabled "Soon" placeholder row (`_SoonRow`) in `TransactionAdvancedSection` | No backing schema exists yet — needs a shape decision (free-form JSON column vs. structured key/value table) before UI is worth adding back. |

---

## Correctness risks

| Item | Evidence | Notes |
| --- | --- | --- |
| Two divergent "next due date" implementations for recurring transactions | Recurring Manager uses `recurring_management.dart::nextDueWithEvents` (honors paid/skipped/snoozed events); the transaction detail sheet and dashboard's upcoming card instead use `upcoming_payments.dart::computeNextPaymentDate`, which never looks at `recurring_events` | A schedule the user just marked "paid" or "snoozed" in the manager can still show its old due date on the dashboard/detail sheet until the underlying transaction row itself changes. Consolidate on one due-date function. See [FEATURES.md](./FEATURES.md#recurring-transactions--recurring-events). |
| "Mark paid" clone has no back-reference to its recurring template, so category-string matching is the only way to exclude it from discretionary spend | `RecurringPaymentsPage._markPaid` (`lib/screens/recurring/recurring_payments_page.dart:171`) inserts a same-category expense clone with `isRecurring` flipped to `false` and drops the parent transaction's `id` (`copyWith(id: null, ...)`) | `DashboardAggregations.discretionaryMonthSpend` excludes clones by matching `TransactionSubtypeHelpers.isEmiCategory`/`isSubscriptionCategory`, which covers EMI/Subscription but not recurring items in "other" categories (rent, a custom-named loan) — those clones still double-count against `spendableToday`'s upfront recurring deduction. Fix properly by giving the clone a `parentTransactionId` (schema change) instead of relying on category text. |

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
