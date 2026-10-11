# Backlog

Living list of known gaps, half-finished features, and structural debt — derived from the current codebase (feature flags, reserved-but-unused hooks, legacy adapters, test coverage) rather than aspirational planning. Update this file as items are picked up or resolved; delete a row rather than leaving it stale once it's done.

Last reviewed: 2026-10-11.

---

## In progress / flagged off

| Item | Evidence | Notes |
| --- | --- | --- |
| Transfer transactions | `FeatureFlags.transferVisible = false` in `lib/config/feature_flags.dart` | Full transfer support exists in the `Transaction` model and `TransactionKind` enum, and existing transfer rows still display/edit correctly, but the flag hides it from quick actions, the type selector, and filters for new entries. Flip the flag once the flow is validated end-to-end. |
| Biometric app-lock | `SplashBootstrapResult.requiresBiometricUnlock` field exists in `lib/services/splash_bootstrap.dart` and is computed, but no screen/gate consumes it yet | Wire a lock screen into `AuthGate` that checks this flag on resume. |
| Dead pre-login onboarding hooks | `SplashDestination.onboarding` and the `onboarding_complete` pref in `lib/services/splash_bootstrap.dart` are never set to `false` by anything; `AuthGate` maps that destination to login | Unrelated to the post-login wizard that shipped (`OnboardingWizardPage`, `financial_profile_onboarding_complete` / `user_settings.onboarding_completed_at`). Three onboarding-shaped keys now coexist; delete the dead enum value and pref key to remove the confusion. |
| Add Transaction → Advanced: Recent suggestions | Removed 2026-08-18 from `TransactionAdvancedSection` (`lib/components/transaction/transaction_advanced_section.dart`); was `RecentSuggestionsSection` (now-deleted `lib/components/transaction/recent_suggestions_section.dart`), tap-to-autofill merchant/category/account/amount from the 5 most recent unique merchants | `RecentSuggestion` model and the expense-side `_buildRecentSuggestions()` builder are gone from `expense_home_page.dart` too. Note: the income-side `recentIncomeSuggestions` data path was **kept** — it still drives the Salary autofill in `add_transaction_page.dart::_applySalaryAutofillIfNeeded` — so re-adding this only needs a UI row wired back to that existing data, not new plumbing. |
| Add Transaction → Advanced: Quick-parse ("AI text") entry | Removed 2026-08-18; was `QuickAiInput` (now-deleted `lib/components/transaction/quick_ai_input.dart`) — free-text row like `240 swiggy using hdfc` parsed into amount/merchant/account/category | The regex-based `_QuickParser`/`_QuickParseResult` in `add_transaction_page.dart` was deleted alongside it (not reused elsewhere). Re-implementing later is a good place to swap the naive regex parser for an actual LLM-backed one, per the "AI text" framing. |
| Add Transaction → Advanced: Attachments | Removed 2026-08-18; was a disabled "Soon" placeholder row (`_SoonRow`) in `TransactionAdvancedSection` | No backing model/storage exists yet — needs a Supabase storage bucket + column on `transactions` before UI is worth adding back. |
| Add Transaction → Advanced: Custom Metadata | Removed 2026-08-18; was a disabled "Soon" placeholder row (`_SoonRow`) in `TransactionAdvancedSection` | No backing schema exists yet — needs a shape decision (free-form JSON column vs. structured key/value table) before UI is worth adding back. |
| Recurring income (salary) not projected forward | Creation already works end-to-end — `Transaction.isRecurring`/`recurrenceFrequency`/`recurrenceEndDate` are kind-agnostic, `RecurringPaymentSection` already has an `isIncome` mode, and `IncomeFlowHelpers.applyCategoryRecurringDefaults` already defaults Salary/Rental to monthly (`lib/utils/income_flow_helpers.dart:72-83`) with an optional, already-editable end date — so a bounded (e.g. 12-month) recurring salary can already be created today, no creation-time gap. But every downstream consumer filters recurring to expense only: `RecurringManagement.build()` (`recurring_management.dart:209`, `!tx.isExpense`), `analytics_aggregations.dart::recurringSummary` (line 369), and `DashboardAggregations.monthIncome` sums only transactions literally dated in the current month, so a recurring salary only counts in the month it was created and silently drops out of the Spending Room / Hero card Income figure every month after. | Requested 2026-08-19, explicitly deferred by the user rather than built now. Two-tier scope, evaluated but not started: **(a) projection-only** — add `monthlyRecurringIncomeTotal` mirroring `monthlyRecurringExpenseTotal` (`dashboard_aggregations.dart:112-124`) and fold it into `monthIncome`; small diff, no new UI, no double-counting risk since no ledger clone is involved. **(b) "Mark Received" ledger materialization** (mirrors the expense-side `_markPaid`, `recurring_payments_page.dart:171`) — meaningfully larger: needs a new UI surface (not the existing Recurring Payments Manager — that screen is entirely bill/EMI-framed), an amount-confirmation step since salary isn't fixed the way an EMI installment is, and reopens the double-counting problem the row above already documents, except income has no `isEmiCategory`/`isSubscriptionCategory`-style signal to exclude the clone with — doing (b) correctly means adding a real `parentTransactionId` back-reference (which would also fix the row above), not another category heuristic. Recommend (a) first if picked back up. |
| "Coming soon" controls | `futureReady: true` on Settings → Data & Privacy → Backup & Sync and Budgets → Overspending Alerts; Transactions tab export button is disabled with a "coming soon" tooltip (`transactions_screen.dart`) | Real CSV export already exists in Data & Privacy (`utils/data_export.dart`); the Transactions-tab button could reuse it for the filtered list. |
| Help Center feedback rows are stubs | Send Feedback, Request a Feature, Report an Issue, Contact Us and Rate the App all call `_stub()` (`help_center_page.dart`) | Wire to `mailto:` (same pattern as `account_deletion_request.dart`) and a store-review link once a real support address exists. |
| "Reset My Account" is self-service but not atomic | Settings → Data & Privacy → Danger Zone → `ApiService.resetUserData()` → `DELETE /v1/data`, which deletes table by table | Shipped 2026-08-20 behind a confirmation dialog (`confirm_reset_account_dialog.dart`); wipes transactions, accounts, categories and budgets but keeps the login and `user_settings`. Guests wipe `GuestStore` instead. A failure part-way leaves a partial wipe; the single-Postgres-function fix is in [TODOS.md](../TODOS.md). Note: an earlier plan (2026-08-19) called for a mail-to-admin request instead; the self-service version is what shipped. |
| "Delete my account" is a manual, mail-triggered request | `SettingsDeleteAccountSection` → typed confirmation → `launchAccountDeletionRequest` (`lib/utils/account_deletion_request.dart`) opens a `mailto:` to `AppInfo.supportEmail` with the user's email and id. Hidden for guests. | Shipped 2026-08-24. Someone still deletes the data and the Auth0 identity by hand; automating it needs Auth0 Management API M2M credentials on `backend/`, which it doesn't hold. `AppInfo.supportEmail` is still `support@REPLACE-ME.com` (P1 in [TODOS.md](../TODOS.md)). Relevant to Apple App Store Guideline 5.1.1(v) (in-app account creation is on, `docs/auth0_setup.md` step 5): a mail request is a defensible interim, not a guaranteed pass. Re-check Apple's bar before submitting. |

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
| `ExpenseHomePage` owns too much | `lib/screens/home/expense_home_page.dart` is ~940 lines and holds transactions/accounts state, all CRUD callbacks, and cross-tab navigation | Noted as a known trade-off in [ARCHITECTURE.md](./ARCHITECTURE.md#state-management). Extracting a dedicated controller/notifier is the natural next step before adding more tabs. |
| Legacy `expenses` table | `sql/` still has the old `expenses` table migration (the Dart `Expense` model and adapters are gone) | The app reads/writes `transactions` exclusively. Plan a careful data migration off the old table, then drop it. |
| No named router | No `go_router` or routes table — navigation is ad hoc `Navigator.push` + tab index | Fine for current scope; blocks deep-linking to arbitrary screens and web URL parity. Listed as a future direction in [ARCHITECTURE.md](./ARCHITECTURE.md#future-improvements). |
| No offline cache | Every signed-in load is a network round trip to the Node API (`backend/`); no local persistence layer beyond `shared_preferences` for small settings | A Drift/Isar cache with sync would improve cold-start and flaky-network UX. |

---

## Test coverage

| Item | Evidence | Notes |
| --- | --- | --- |
| Thin test coverage | `test/` has 11 files: models (`transaction`, `user_settings`), services (`GuestStore`, `ApiService` guest routing + response decoding), utils (`dashboard_aggregations`, `data_export`, `subscription_catalog`, `account_deletion_request`, `onboarding_locale_currency`), `app_launch_intent_test.dart`, and `widget_test.dart` (pumps a hardcoded `MaterialApp` stub, not the real app). The backend has its own node:test suite in `backend/test/`. | No coverage for `analytics_aggregations.dart`, `financial_insights.dart`, or any screen/widget flow (transactions, recurring, accounts, settings). The two aggregation utils are pure logic and cheap to test first. |

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
