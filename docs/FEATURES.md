# Feature Rules

Catalog of the app's features and the concrete business/validation rules governing each — sourced from the actual model, service, and utils logic (not the UI). Every non-obvious rule is cited as `file.dart::function_or_field`. Where a feature area has no logic beyond plain CRUD, that's stated rather than invented.

This is the "what happens and why" reference. For code structure see [ARCHITECTURE.md](./ARCHITECTURE.md), for visual conventions see [DESIGN.md](./DESIGN.md), for known gaps see [BACKLOG.md](./BACKLOG.md).

---

## Transactions (expense / income / transfer)

One unified `Transaction` model covers all three kinds, persisted in `public.transactions`.

- Three kinds exist — `expense`, `income`, `transfer` (`transaction_draft.dart::TransactionKind`) — but `transfer` is currently hidden from new-entry UI by `FeatureFlags.transferVisible = false`; existing transfer rows still display/edit normally. See [BACKLOG.md](./BACKLOG.md) for status.
- If the merchant/payer name is left blank on save, it falls back to the category name, then a kind-specific default — `'Untitled'` (expense), `'Income'` (income), `'Transfer'` (transfer) (`transaction.dart::TransactionDraftPersistence._defaultLabelForKind`).
- `transferToAccountId` is only ever persisted when `kind == transfer`; it's silently dropped for expense/income even if a draft happens to carry one (`transaction.dart::toTransaction`).
- Currency defaults to `INR` if the draft doesn't specify one; empty notes are stored as `null`, not `''` (`transaction.dart::toTransaction`).
- Recurring fields (`recurrenceFrequency`, start/end date, reminder timing) are only written to the row when `isRecurring` is true — turning recurring off clears them on next save (`transaction.dart::toMap`).
- Duplicating a transaction creates a new row (fresh `id`) dated "now", not the original transaction's date (`expense_home_page.dart::_duplicateTransaction`).
- Deletes are hard deletes, scoped to the owning user (`supabase_service.dart::deleteTransaction`).

### Filtering, search, sort, grouping

- The Type filter (`expense`/`income`/`transfer`/`emi`/`subscription`/`refund`) is a **derived** classification, not a stored column: transfer kind → transfer; income + category containing "refund" → refund; expense + category containing "emi" → emi; expense + category containing "subscription" → subscription; else plain expense/income. The category match is a case-insensitive **substring** check, not an exact enum (`transaction_subtype_helpers.dart::displayTypeForTransaction`, `isEmiCategory`, `isSubscriptionCategory`, `isRefundCategory`).
- `transfer` only appears as a selectable filter option when `FeatureFlags.transferVisible` is true (`transaction_filters.dart::kTransactionTypeFilterOptions`).
- Search matches (case-insensitive, substring) merchant name, category, source account name, destination account name, and note simultaneously (`transaction_filter_logic.dart::apply`).
- Date presets — Today, This Week, This Month, Last Month, Custom. "This Week" always starts **Monday**, independent of the `WeekStartDay` app setting (see [Currency & display settings](#currency--display-settings) — that setting isn't actually consumed here) (`transaction_filter_logic.dart::dateRangeForPreset`).
- Amount filter is an inclusive `min ≤ amount ≤ max` range.
- Sort options: latest first (default), highest amount, lowest amount.
- Sort/date-preset/category/account filter state persists locally per device and is restored on next visit; **search text and amount range are not persisted** (`transaction_list_preferences.dart`).
- List grouping buckets, in display order: Today → Yesterday → Earlier This Week (before yesterday, still within the Monday-start week) → This Month → one bucket per older calendar month, newest first (`transaction_grouping.dart::groupTransactionsByDate`).

---

## Recurring transactions & recurring events

`isRecurring` transactions represent a repeating schedule (subscription, EMI, or generic recurring expense). A separate `recurring_events` table records per-occurrence user actions (paid / skipped / snoozed) without touching the schedule row itself.

- Subscription vs. EMI vs. "other recurring" is derived purely from a case-insensitive substring match on `category` ("emi" / "subscription") — there's no dedicated type column (`recurring_management.dart::classify`).
- A schedule is **closed** (cancelled subscription, completed EMI, etc.) via a `closedAt` timestamp, not a delete. Closed schedules are excluded entirely — no card, no upcoming-timeline entry, no monthly-total contribution. Undo clears `closedAt` back to `null` (`recurring_management.dart::build` filters `tx.isClosed`; `supabase_service.dart::setTransactionClosed`).
- A schedule can independently be **paused** (`isPaused`). Paused schedules have no next due date and drop out of the upcoming timeline, but — unlike closed — still render as a card in the manager (`recurring_management.dart::nextDueWithEvents`, `RecurringScheduleItem.isAutoDeduct`).
- **Next-due-date algorithm** (`recurring_management.dart::nextDueWithEvents`): walk forward from `recurrenceStartDate` (or `date`) one cycle at a time. For each candidate occurrence — if a `paid`/`skipped` event exists for that date, skip past it; if a `snoozed` event exists, defer to its `snoozeUntil` (unless that date has already lapsed, in which case the occurrence is treated as due today); otherwise return the first occurrence that isn't in the past. Capped at 500 iterations.
- Recurring events are idempotent on `(user_id, transaction_id, occurrence_date, event_type)` — repeated taps on the same swipe action upsert rather than duplicate, backed by a unique index in `sql/20260528_recurring_events.sql` (`supabase_service.dart::insertRecurringEvent`).
- **"Auto-deduct" badge is inferred, not stored**: `reminderTiming == null` is read as "user didn't configure a manual reminder," which the UI treats as "this charge auto-deducts" (`upcoming_payments.dart` / `recurring_management.dart`, `UpcomingPaymentItem.isAutoDeduct`, `RecurringScheduleItem.isAutoDeduct`).
- Monthly-equivalent normalization (used for manager totals, analytics, and insights alike): weekly ×4.33, daily ×30, quarterly ÷3, yearly ÷12; monthly/custom/unset unchanged. This formula is implemented independently in three places (`recurring_management.dart::monthlyEquivalent`, `analytics_aggregations.dart::_normaliseMonthly`, `financial_insights.dart::_normaliseToMonthly`) rather than shared from one source.
- **EMI progress** is computed purely from user-entered start/end dates — not a real amortization schedule. Total months = inclusive month-diff between start and end; completed = months elapsed from start to now (clamped to total); remaining principal = remaining months × the transaction's flat per-installment amount (no interest modeling). Returns `null` if there's no end date or the category isn't EMI-classified (`recurring_management.dart::emiProgress`).
- The upcoming-payments timeline (Recurring Manager) defaults to a **60-day lookahead**, bucketed as Today / Tomorrow / This Week (≤7 days) / Later This Month (`recurring_management.dart::build`, `lookaheadDays: 60`).
- Recurring transactions can appear multiple times in the in-memory transaction cache; both the manager and the analytics recurring summary de-duplicate on a signature (`id`, or `merchant|amount|frequency` if no id) so monthly totals aren't double-counted (`recurring_management.dart::_scheduleSignature`, `analytics_aggregations.dart::recurringSummary`).
- **Note — two independent "next due date" implementations exist.** The Recurring Manager uses `nextDueWithEvents` (honors pause/paid/skipped/snoozed events). The transaction detail sheet and dashboard's upcoming card instead use the simpler `computeNextPaymentDate` (`upcoming_payments.dart`), which does **not** look at `recurring_events` at all — a schedule the user just marked "paid" or "snoozed" in the manager can still show its old due date on the dashboard until the underlying transaction data changes.

---

## Accounts (bank / wallet / credit card)

Balances and credit metrics are always computed on the fly from transaction history — nothing is cached/stored as a running balance.

- **Account balance** = `openingBalance` + Σ(income to this account) − Σ(expense from this account), plus transfers (a transfer decreases the source account's balance and increases the destination's) (`dashboard_aggregations.dart::accountBalance`).
- **Credit card outstanding** = the account's negative running balance, flipped positive; if the balance isn't negative, outstanding is `0` (`account_management.dart::creditOutstanding`).
- **Credit utilization ratio** = outstanding ÷ creditLimit, clamped to `[0, 1]`; available credit = creditLimit − outstanding, clamped to `[0, limit]`. Both default to `0` if no credit limit is set (`account_management.dart::creditUtilization`).
- **Utilization warning tone**: ≥85% → danger, ≥60% → warning, else none (`account_management.dart::_utilizationTone`).
- **"Used this month" on the dashboard glance is a month-to-date proxy** — sum of this calendar month's expense transactions on the card — explicitly *not* aware of the card's actual statement cycle (the code comment calls this out directly) (`dashboard_aggregations.dart::creditCardUsed`).
- Statement/due-date labels: if the account's `statementDay`/`dueDay` (1–31) has already passed this month, the label rolls to next month (`account_management.dart::_nextDayOfMonth`, `billingLabels`).
- An account is "due soon" when its computed due date is 0–7 days out, inclusive (`account_management.dart::dueSoon`).
- Cash/bank/wallet balances are **clamped to ≥0** when rolled into the "Total available"/"Cash available" dashboard headline figures — a negative bank balance won't drag those totals negative (`account_management.dart::buildSnapshot`).
- Archiving an account is a soft delete (`isArchived = true`); it preserves transaction foreign keys and is excluded from `fetchAccounts()` by default (`supabase_service.dart::fetchAccounts`).
- A wallet/UPI account is `type == other` with a non-null `walletProvider`; its display label falls back to `providerName`, then the wallet provider's label (`account.dart::isWallet`, `providerLabel`).
- A credit card can be **linked** to a paying bank/wallet account via `linkedAccountId`. Paying a credit card bill from the dashboard shortcut pre-fills an expense draft against the linked account (falling back to the card itself if unlinked), labeled `"{card name} bill payment"` (`expense_home_page.dart::_payCreditBill`).

---

## Categories (expense & income catalogs)

Separate per-user catalogs for expense and income categories; identical rules apply to both (`category_catalog.dart` and `income_category_catalog.dart` are structurally 1:1).

- Default categories are seeded **idempotently** — on sync, only default names missing from the user's catalog (case-insensitive match) are inserted; existing rows are untouched (`supabase_service.dart::ensureDefaultCategories` / `ensureDefaultIncomeCategories`).
- Default categories cannot be deleted — enforced both client-side (`CategoryCatalog.deleteCategory` throws) and at the query level (`deleteCategory` filters `is_default = false`).
- A custom category name must be non-empty and unique case-insensitively within the user's catalog, checked client-side before any network call (`category_catalog.dart::addCategory`).
- If remote sync fails outright (e.g. first launch offline), the catalog falls back to an **in-memory, unpersisted** set of default categories so pickers never render empty (`category_catalog.dart::_syncForUser` catch path → `_loadLocalDefaults`).
- Signing out immediately clears the in-memory catalog and reloads local (unsynced) defaults, so a new sign-in never briefly shows the previous user's custom categories (`category_catalog.dart::onSignedOut`).

---

## Budgets (category budgets)

One optional monthly spending limit per expense category name — no rollover, no per-account budgets.

- At most one budget per `(user_id, category_name)`, enforced by a case-insensitive unique index; saving a budget for an already-budgeted category **replaces** it via upsert (`supabase_service.dart::upsertCategoryBudget`, `sql/20260527_dashboard_data.sql`).
- A budget requires a selected category and a strictly positive amount, or the save is rejected client-side (`category_budget_service.dart::upsert`).
- No rollover exists: "spent" is recomputed fresh from raw transactions for the target month every time — nothing persists a "remaining balance" across months (`analytics_aggregations.dart::budgetSpend`).
- Recommended daily spend = (monthlyLimit − monthSpent) ÷ daysRemainingInMonth. Returns `0` (not negative) once the limit is exceeded; returns the full remaining amount undivided if computed on/after the last day of the month (`dashboard_aggregations.dart::safeDailySpend`, `daysRemainingInMonth`).
- The dashboard's budget-proximity insight (below) only ever surfaces the **first** budget it encounters that's near/over limit — not all of them — because the loop returns on first match (`financial_insights.dart::_budgetProximity`).

---

## Analytics & financial insights

Pure aggregation functions over the full in-memory transaction list; nothing is pre-aggregated server-side.

- Selectable ranges: This Week (Monday-start), This Month, Last Month, 3 Months, 6 Months, This Year, Custom. Multi-month ranges use monthly trend buckets; This Week/Month/Last Month use weekly buckets (`analytics_aggregations.dart::AnalyticsRange.isMultiMonth`, `incomeVsExpenseBuckets`).
- Every range has an implicit **previous period of equal length** for delta comparisons (e.g. a 6-month range compares against the preceding 6 months) (`ResolvedRange.previous`).
- Period-over-period delta (spend, income, per-category) is `null` — not `0%` or a huge negative number — whenever the prior period had zero or negative activity, to avoid a nonsensical percentage (`AnalyticsAggregations._delta`).
- Savings rate = (income − spend) ÷ income, and is `null` (hidden, not shown as `-∞%`) whenever income is `0` (`AnalyticsOverview.savingsRate`, `PeriodBucket.savingsRate`).
- Category breakdown share = category total ÷ grand total expense for the period; blank/whitespace-only category names are bucketed as `"Other"` (`analytics_aggregations.dart::categoryBreakdown`).
- The weekday-spending profile chart is suppressed entirely (returns `null`) unless there are **at least 5 distinct spending days** in the selected range, to avoid drawing conclusions from too little data (`analytics_aggregations.dart::weekdayProfile`).
- Budget progress always snaps to the calendar month containing the **end** of the selected range — picking "3 Months" still shows current-cycle (not 3-month-summed) budget progress (`analytics_aggregations.dart::budgetSpend`).

### Dashboard insights (rule-based, deterministic — `financial_insights.dart`)

- **Category spend spike**: flags a category if this-month spend is up ≥15% vs. last month (categories with zero/negative prior-month spend are excluded from consideration); escalates to "warning" tone at ≥35%. Only the single category with the **largest** increase is surfaced, not every category crossing 15% (`_categoryDelta`).
- **Weekend skew**: flags if average weekend (Sat/Sun) daily spend this month exceeds 1.4× average weekday daily spend — using fixed divisors of 8 weekend-days and 22 weekday-days per month rather than the actual calendar day count for the current month (`_weekendSkew`).
- **Subscriptions cost**: surfaces total monthly-equivalent cost of active recurring transactions categorized as "Subscription," only if at least one exists with total > 0 (`_subscriptionsCost`).
- **Budget proximity**: iterates budgets in list order; the first one with month-to-date spend ≥100% of its limit produces a "danger" insight and stops; otherwise the first one ≥85% produces a "warning" insight and stops. At most one budget insight renders per dashboard build (`_budgetProximity`).

---

## Currency & display settings

A single app-wide default display currency — not per-transaction or per-account conversion.

- 10 supported currencies (USD default, EUR, GBP, INR, CAD, AUD, JPY, CHF, SGD, AED). Setting an unsupported code is a silent no-op (`currency_settings.dart::setCurrency`, `isSupportedCode`).
- JPY is the only currency with 0 decimal digits; all others use 2 (`currency_settings.dart::decimalDigits`).
- On first sign-in, if the user has no remote `user_settings` row, one is created server-side using the current local currency as the default rather than left unset (`currency_settings.dart::syncForUser`).
- Currency is cached under both a per-user SharedPreferences key and a global fallback key, so the last-used currency renders immediately on cold start before remote sync completes (`currency_settings.dart::_prefKeyFor`, `_cacheLocally`).
- `Transaction.currencyCode` is stored per-row, but the app is single-currency by design — there is no conversion; each transaction simply records whatever currency was active when it was saved.
- **`WeekStartDay` (Mon/Sun) and `FinancialYear` (Jan–Dec / Apr–Mar) exist as settings but are not consumed anywhere else in the codebase** — verified no reads outside `settings_preferences.dart` and its own settings-page UI. Date-preset filtering (`transaction_filter_logic.dart`) and transaction-list grouping (`transaction_grouping.dart`) both hardcode Monday-start weeks and calendar-year months regardless of what the user picks here.

---

## Auth & user scoping

Auth0 handles identity; Supabase stores data; every row is scoped by the Auth0 `sub` claim as `user_id`.

- Every Supabase read/write goes through `SupabaseService.requireUserId()`, which throws if there's no active session — there's no code path that queries without a user filter (`supabase_service.dart::requireUserId`, used in every method).
- The Auth0 ID token is passed to Supabase via a custom `accessToken` callback so Postgres RLS can enforce the same scoping server-side (`supabase_service.dart::init`).
- On sign-in, `AuthGate` triggers `syncForUser()` on every user-scoped singleton (`CategoryCatalog`, `IncomeCategoryCatalog`, `CategoryBudgetService`, `CurrencySettings`, `SettingsPreferences`) so cached state reflects the newly signed-in user.
- On sign-out, each of those singletons runs `onSignedOut()`, clearing in-memory state (and, for catalogs, reloading local unsynced defaults) so no data from the previous session lingers in memory for a subsequent sign-in.
- Login callback scheme differs by platform: Android always uses HTTPS app links; iOS/macOS use a custom URL scheme unless `AppConfig.auth0UseHttps` is explicitly set (`auth_service.dart::_useHttpsCallbacks`).
- A user cancelling the Auth0 web login is surfaced as a distinct `AuthLoginCancelledException`, not a generic error (`auth_service.dart::login`).
- Splash bootstrap reserves (but does not yet implement) two future gates: a biometric-unlock step (`SplashBootstrapResult.requiresBiometricUnlock`, currently hardcoded to always return `false`) and an onboarding destination (`SplashDestination.onboarding`, reachable only if a local `onboarding_complete` pref is explicitly set `false`, which nothing in the app currently does) — see [BACKLOG.md](./BACKLOG.md).

---

## Deep link / widget quick-add intent

The iOS home-screen widget (and any `expensetracker://` link) can launch the app directly into the add-expense flow.

- Only one intent currently exists: `AppLaunchIntent.addExpense`, matched from `expensetracker://add-expense` (host or first path segment, case-insensitive); any other path is ignored (`app_launch_intent.dart::fromUri`).
- The intent is consumed exactly once — `consume()` reads and clears it — so re-navigating within the app afterward won't re-trigger the add flow (`app_launch_intent.dart::consume`).
- On app resume, links are re-captured up to 4 times at staggered delays (0ms, 200ms, 600ms, 1200ms) after the home screen mounts, because widget taps can arrive slightly after the first frame (`expense_home_page.dart::_scheduleLaunchIntentChecks`).
- A pending intent is only acted on once the transaction list has finished loading and no add-transaction screen is already open, to avoid double-pushing the add flow (`expense_home_page.dart::_tryHandleLaunchIntent`).

---

## Related docs

- [ARCHITECTURE.md](./ARCHITECTURE.md) — app structure, services, navigation, state management
- [DESIGN.md](./DESIGN.md) — design tokens, shared UI primitives, motion
- [DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md) — Postgres schema, ER diagram, migration order
- [BACKLOG.md](./BACKLOG.md) — known gaps, flagged-off features, structural debt
