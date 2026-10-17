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
- Deletes are hard deletes, scoped to the owning user by the backend (`api_service.dart::deleteTransaction` → `DELETE /v1/transactions/:id`).

### Filtering, search, sort, grouping

- The Type filter (`expense`/`income`/`transfer`/`emi`/`subscription`/`refund`) is a **derived** classification, not a stored column: transfer kind → transfer; income + category containing "refund" → refund; expense + category containing "emi" → emi; expense + category containing "subscription" → subscription; else plain expense/income. The category match is a case-insensitive **substring** check, not an exact enum (`transaction_subtype_helpers.dart::displayTypeForTransaction`, `isEmiCategory`, `isSubscriptionCategory`, `isRefundCategory`).
- `transfer` only appears as a selectable filter option when `FeatureFlags.transferVisible` is true (`transaction_filters.dart::kTransactionTypeFilterOptions`).
- Search matches (case-insensitive, substring) merchant name, category, source account name, destination account name, and note simultaneously (`transaction_filter_logic.dart::apply`).
- Date presets — Today, This Week, This Month, Last Month, Custom. "This Week" always starts **Monday**; there is no week-start setting (`transaction_filter_logic.dart::dateRangeForPreset`).
- Amount filter is an inclusive `min ≤ amount ≤ max` range.
- Sort options: latest first (default), highest amount, lowest amount.
- Sort/date-preset/category/account filter state persists locally per device and is restored on next visit; **search text and amount range are not persisted** (`transaction_list_preferences.dart`).
- List grouping buckets, in display order: Today → Yesterday → Earlier This Week (before yesterday, still within the Monday-start week) → This Month → one bucket per older calendar month, newest first (`transaction_grouping.dart::groupTransactionsByDate`).

---

## Recurring transactions & recurring events

`isRecurring` transactions represent a repeating schedule (subscription, EMI, or generic recurring expense). A separate `recurring_events` table records per-occurrence user actions (paid / skipped / snoozed) without touching the schedule row itself.

- Subscription vs. EMI vs. "other recurring" is derived purely from a case-insensitive substring match on `category` ("emi" / "subscription") — there's no dedicated type column (`recurring_management.dart::classify`).
- A schedule is **closed** (cancelled subscription, completed EMI, etc.) via a `closedAt` timestamp, not a delete. Closed schedules are excluded entirely — no card, no upcoming-timeline entry, no monthly-total contribution. Undo clears `closedAt` back to `null` (`recurring_management.dart::build` filters `tx.isClosed`; `api_service.dart::setTransactionClosed`).
- A schedule can independently be **paused** (`isPaused`). Paused schedules have no next due date and drop out of the upcoming timeline, but — unlike closed — still render as a card in the manager (`recurring_management.dart::nextDueWithEvents`, `RecurringScheduleItem.isAutoDeduct`).
- **Next-due-date algorithm** (`recurring_management.dart::nextDueWithEvents`): walk forward from `recurrenceStartDate` (or `date`) one cycle at a time. For each candidate occurrence — if a `paid`/`skipped` event exists for that date, skip past it; if a `snoozed` event exists, defer to its `snoozeUntil` (unless that date has already lapsed, in which case the occurrence is treated as due today); otherwise return the first occurrence that isn't in the past. Capped at 500 iterations.
- Recurring events are idempotent on `(user_id, transaction_id, occurrence_date, event_type)` — repeated taps on the same swipe action upsert rather than duplicate, backed by a unique index in `sql/20260528_recurring_events.sql` (`api_service.dart::insertRecurringEvent`).
- **"Auto-deduct" badge is inferred, not stored**: `reminderTiming == null` is read as "user didn't configure a manual reminder," which the UI treats as "this charge auto-deducts" (`upcoming_payments.dart` / `recurring_management.dart`, `UpcomingPaymentItem.isAutoDeduct`, `RecurringScheduleItem.isAutoDeduct`).
- Monthly-equivalent normalization (used for manager totals, analytics, insights, and the home screen's Spending Room card alike): weekly ×4.33, daily ×30, quarterly ÷3, yearly ÷12; monthly/custom/unset unchanged. Shared from one source, `recurrence_normalization.dart::monthlyEquivalent`.
- **EMI progress** is computed purely from user-entered start/end dates — not a real amortization schedule. Total months = inclusive month-diff between start and end; completed = months elapsed from start to now (clamped to total); remaining principal = remaining months × the transaction's flat per-installment amount (no interest modeling). Returns `null` if there's no end date or the category isn't EMI-classified (`recurring_management.dart::emiProgress`).
- The upcoming-payments timeline (Recurring Manager) defaults to a **60-day lookahead**, bucketed as Today / Tomorrow / This Week (≤7 days) / Later This Month (`recurring_management.dart::build`, `lookaheadDays: 60`).
- Recurring transactions can appear multiple times in the in-memory transaction cache; both the manager and the analytics recurring summary de-duplicate on a signature (`id`, or `merchant|amount|frequency` if no id) so monthly totals aren't double-counted (`recurring_management.dart::_scheduleSignature`, `analytics_aggregations.dart::recurringSummary`).
- **Note — two independent "next due date" implementations exist.** The Recurring Manager uses `nextDueWithEvents` (honors pause/paid/skipped/snoozed events). The transaction detail sheet and dashboard's upcoming card instead use the simpler `computeNextPaymentDate` (`upcoming_payments.dart`), which does **not** look at `recurring_events` at all — a schedule the user just marked "paid" or "snoozed" in the manager can still show its old due date on the dashboard until the underlying transaction data changes.

---

## Subscription picker & brand icons

A curated, fixed list of ~20 common subscriptions (Netflix, Spotify, etc.) that a user can pick from instead of free-typing the merchant, so the transaction gets a recognizable brand-colored badge instead of the generic category icon.

- The catalog is a hand-maintained `const` list, not a database table or user-editable — same shape as `DefaultCategories.seeds` (`subscription_catalog.dart::SubscriptionCatalog.entries`).
- Matching is **exact, case-insensitive** on `Transaction.counterpartyName` — not the substring match `isSubscriptionCategory` uses on `category`. "Netflix Gift Card" or "My Netflix" will **not** match "Netflix" (`subscription_catalog.dart::SubscriptionCatalog.forName`).
- **This is a second, independent classification axis from the existing category-string-based one** (`isSubscriptionCategory`/`RecurringKind.subscription` in `recurring_management.dart`). A transaction can be "Subscription" by category without matching the catalog (e.g. a subscription not in the curated list), and vice versa is not possible since picking from the catalog always sets category to "Subscription" too. Reconciling these two mechanisms into one is tracked as a TODO — see `TODOS.md`.
- Brand marks are **generated placeholder badges** (solid brand-color square + first letter), rendered as a Flutter widget (`SubscriptionBadge`), not bundled image assets — this app has no image-generation tooling, and a widget avoids the whole "what if the asset fails to load" question entirely, since there's no I/O to fail. Real logos (if ever swapped in) are a separate TODO with its own legal-check item.
- Picking a subscription (Add Transaction's picker, or long-press on an existing row) fills `counterpartyName` with the catalog's canonical spelling — **overwriting** whatever was typed/already stored. Category + recurring defaults (`enabled: true`, `frequency: monthly`) are applied via the existing `applyExpenseSubtype` helper, matching the manual Subscription quick-pick's behavior exactly (`add_transaction_page.dart::_onSubscriptionPicked`, `expense_home_page.dart::_tagTransactionAsSubscription`).
  - On the **Add Transaction** picker, the category/recurring defaults are only applied if the category is currently unset or still the catalog default — so it never clobbers a category the user already deliberately chose.
  - On **long-press retroactive tagging** of an existing row, category + recurring are applied unconditionally — the whole point of that action is "make this a tagged subscription."
- The brand-badge resolution (subscription match → badge; no match → today's generic category icon, unchanged) is independently re-implemented at **6 render sites** because this app has no single shared transaction-icon rendering path: `transaction_list_item.dart`, `subscription_card.dart`, `upcoming_payment_tile.dart`, `analytics/subscriptions_section.dart`, `home/dashboard/recent_transactions_section.dart`, and the picker sheet's own rows. Subscription matching is expense-only — income and transfer rows always fall back to the category icon.
- A one-time onboarding tip (covering both the picker button and long-press) shows once on the Add Transaction screen, gated by a `SharedPreferences` bool (`add_transaction_page.dart::_kSeenSubscriptionTip`), and is dismissed permanently once tapped away.

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
- Archiving an account is a soft delete (`isArchived = true`); it preserves transaction foreign keys and is excluded from `fetchAccounts()` by default (`api_service.dart::fetchAccounts`).
- A wallet/UPI account is `type == other` with a non-null `walletProvider`; its display label falls back to `providerName`, then the wallet provider's label (`account.dart::isWallet`, `providerLabel`).
- A credit card can be **linked** to a paying bank/wallet account via `linkedAccountId`. Paying a credit card bill from the dashboard shortcut pre-fills an expense draft against the linked account (falling back to the card itself if unlinked), labeled `"{card name} bill payment"` (`expense_home_page.dart::_payCreditBill`).

---

## Categories (expense & income catalogs)

Separate per-user catalogs for expense and income categories; identical rules apply to both (`category_catalog.dart` and `income_category_catalog.dart` are structurally 1:1).

- On Add Transaction → income, the category list shows the 4 most-used income categories plus a "More (N)" row; it stays expanded when the current selection would otherwise be hidden (`transaction_primary_fields.dart`).
- Default categories are seeded **idempotently** — on sync, only default names missing from the user's catalog (case-insensitive match) are inserted; existing rows are untouched (`api_service.dart::ensureDefaultCategories` / `ensureDefaultIncomeCategories`).
- Default categories cannot be deleted — enforced both client-side (`CategoryCatalog.deleteCategory` throws) and by the backend (`DELETE /v1/categories/{expense,income}/:id` filters `is_default = false`, still returning 204).
- A custom category name must be non-empty and unique case-insensitively within the user's catalog, checked client-side before any network call (`category_catalog.dart::addCategory`).
- If remote sync fails outright (e.g. first launch offline), the catalog falls back to an **in-memory, unpersisted** set of default categories so pickers never render empty (`category_catalog.dart::_syncForUser` catch path → `_loadLocalDefaults`).
- Signing out immediately clears the in-memory catalog and reloads local (unsynced) defaults, so a new sign-in never briefly shows the previous user's custom categories (`category_catalog.dart::onSignedOut`).

---

## Budgets (category budgets)

One optional monthly spending limit per expense category name — no rollover, no per-account budgets.

- At most one budget per `(user_id, category_name)`, enforced by a case-insensitive unique index; saving a budget for an already-budgeted category **replaces** it via upsert (`api_service.dart::upsertCategoryBudget`, `sql/20260527_dashboard_data.sql`).
- A budget requires a selected category and a strictly positive amount, or the save is rejected client-side (`category_budget_service.dart::upsert`).
- A separate, optional **Monthly Spending Limit** (a global cap, stored in `SettingsPreferences.monthlySpendingLimit`) sits above the category budgets. It's informational only: nothing outside the Budgets screen, budget sheet and onboarding budget step reads it, so it doesn't feed Spending Room or insights.
- When both a limit and category budgets exist, a live allocation note compares Σ category budgets to the limit: within 0.5 → "Fully allocated", above → "Over-allocated by X" (warning), below → "X unallocated" (spend outside budgeted categories still counts toward the limit). While editing a budget, the note recomputes with the typed amount replacing that category's existing budget, not adding to it (`budget_edit_sheet.dart::BudgetAllocationNote`).
- No rollover exists: "spent" is recomputed fresh from raw transactions for the target month every time — nothing persists a "remaining balance" across months (`analytics_aggregations.dart::budgetSpend`).
- The dashboard's budget-proximity insight (below) only ever surfaces the **first** budget it encounters that's near/over limit — not all of them — because the loop returns on first match (`financial_insights.dart::_budgetProximity`).

---

## Spending Room (home screen "how much can I spend today")

Budgets screen → Guardrails → "Safe Daily Spend" toggle (on by default, `settings_preferences.dart::safeDailySpendEnabled`) gates a card below the home screen's Total Balance hero.

- Formula: `totalMonthIncome − monthSpend` — this month's income (logged + projected recurring) minus every expense logged this month, recurring or not (`dashboard_aggregations.dart::spendableToday`). A plain running balance, not a daily-accrued allowance: it's the same number all month, moving only when income or spend is logged.
- **Resets every calendar month — no rollover.** Unspent (or overspent) balance does not carry into the next month (v1 scope decision — rollover was considered and deliberately deferred, see `docs/BACKLOG.md` if revisited).
- Previously accrued a daily allowance by pacing `monthIncome − monthlyRecurringExpenseTotal` out across the month and comparing it to non-recurring spend so far — changed because that model reads as overspent early in the month (before the daily allowance has accrued much) even when money is actually still left, especially for accounts with no recurring commitments logged. `monthlyRecurringExpenseTotal`/`discretionaryMonthSpend` remain as tested utilities but are no longer used by this card.
- When no income has been logged for the current month yet, the card shows a distinct prompt state instead of a large negative number (`SpendingRoomCard` / `hasIncomeThisMonth`).

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
- Theme (Light / Dark, default Dark) and accent (Teal / Blue / Purple, default Teal) live in Settings → Appearance. Both are `SettingsPreferences` values, cached locally and synced in `user_settings.preferences`; `main.dart` pushes them into `AppColors.configure` on every rebuild.
- There are no week-start or financial-year settings. Weeks start Monday and months are calendar months everywhere (`transaction_filter_logic.dart`, `transaction_grouping.dart`, `analytics_aggregations.dart`).

---

## Auth & user scoping

Supabase Auth handles identity; every row is scoped by the user's id (the access token's `sub` claim) as `user_id`.

- The app never sends `user_id`. Every request carries the Supabase access token, and the backend verifies it and forces `user_id` = token `sub` on every query. Signed-out calls fail in `api_service.dart::_send` before any network request (`backend/src/middleware/auth.js`).
- The backend forwards the same token to Supabase so Postgres RLS enforces the scoping again. RLS is the real enforcement point, since the publishable key (in the app) + a user's token can still reach PostgREST directly ([BACKEND.md](./BACKEND.md)).
- On sign-in, `AuthGate` triggers `syncForUser()` on every user-scoped singleton (`CategoryCatalog`, `IncomeCategoryCatalog`, `CategoryBudgetService`, `CurrencySettings`, `SettingsPreferences`) so cached state reflects the newly signed-in user.
- On sign-out, each of those singletons runs `onSignedOut()`, clearing in-memory state (and, for catalogs, reloading local unsynced defaults) so no data from the previous session lingers in memory for a subsequent sign-in.
- Sign-in options: email + password, Google (native sheet, iOS and Android), Sign in with Apple (iOS only, required there by App Store guideline 4.8). Phone OTP is not offered yet (`login_page.dart`).
- Sign-up requires confirming the email with a 6–10 digit code (`validators.dart::validateCode`); signing in to an unconfirmed account resends the code and opens that screen. "Resend code" has a 60 s cooldown (`verify_email_page.dart`).
- Passwords need at least 8 characters, matching the Supabase setting (`validators.dart::minPasswordLength`). Forgot password = emailed code + new password; the code signs the user in (`AuthService.resetPassword`).
- A user cancelling the Google or Apple sheet is surfaced as a distinct `AuthLoginCancelledException` and doesn't show an error (`login_page.dart::_run`).
- Apple sends the user's name only on the first authorization; it's saved to `user_metadata.full_name` immediately so onboarding can pre-fill it (`AuthService.signInWithApple`).
- The session (with the refresh token) is stored in the Keychain/Keystore, not SharedPreferences (`_SecureSessionStorage`). Token refreshes don't re-trigger `AuthGate`'s sign-in handling; only a change of user does (`AuthService.setUser`).
- "Delete Account" (signed-in users only, typed `DELETE` confirmation) deletes every row and then the login itself via `DELETE /v1/account`, then signs out (`data_privacy_page.dart::_deleteAccount`).
- Splash bootstrap reserves (but does not yet implement) a biometric-unlock step (`SplashBootstrapResult.requiresBiometricUnlock`, hardcoded to `false`). Its `SplashDestination.onboarding` is dead code, unrelated to the post-login wizard below — see [BACKLOG.md](./BACKLOG.md).

---

## Guest mode

"Continue as guest" on the login screen (behind `FeatureFlags.guestModeEnabled`) skips sign-in. Data never leaves the device.

- `AuthService.isGuest` is persisted to SharedPreferences, so a guest stays a guest across restarts. `SplashBootstrap` and `AuthGate` treat it like a live session (`auth_service.dart`, `auth_gate.dart`).
- Every `ApiService` method checks `_isGuest` first and routes to `GuestStore`. Each table is a JSON list under its own `guest.*` key; ids are negative and come from one local counter (`guest_store.dart`).
- On the first real sign-in with guest data present, a confirm dialog shows rough counts and offers to bring the data in (`confirm_guest_migration_dialog.dart`). Declined data stays local and can be imported later from Settings → Data & Privacy, which only shows that section to a signed-in user who still has guest data (`SettingsGuestDataSection`).
- Migration replays accounts → categories → transactions → recurring events → budgets, remapping foreign keys. Accounts and categories matching an existing name are reused, not duplicated. User settings are not replayed. Any failure deletes everything that attempt inserted, in reverse order, and leaves `GuestStore` untouched for a retry (`guest_migration_service.dart`).
- Guests don't see "Delete my account" (there is no account); "Reset My Account" wipes `GuestStore`.

---

## Post-login onboarding wizard

A 6-step first-run wizard, shown once per account before the dashboard (behind `FeatureFlags.postLoginOnboardingEnabled`). Design: [designs/post-login-onboarding.md](./designs/post-login-onboarding.md).

- Steps: name → currency → monthly budget → accounts → income → recurring. Each can be skipped; an in-UI Back button moves backward, but hardware back is blocked for the whole wizard (`onboarding_wizard_page.dart`).
- Accounts come before income and recurring so those steps have an account to attach to. Income saves inline with an account picker that defaults to the first account; recurring items open the real `AddTransactionPage` and are listed as "Added" on the step.
- Income is guarded against a duplicate save if an interrupted run resumes. Recurring is not: adding several items is the intended flow.
- Completion is local-first: the `financial_profile_onboarding_complete` pref decides; if it was never set (fresh install, second device), the remote `user_settings.onboarding_completed_at` is checked. Rows that predate the feature were backfilled as complete (`onboarding_wizard_status.dart`, `sql/20260824_onboarding_completed_at.sql`). Guests use a flag in `GuestStore`, copied to the server on migration.
- Default currency is suggested from the device locale (`onboarding_locale_currency.dart`). Local-only counters (started / completed / skipped per step) live in `onboarding_analytics.dart` and are never sent anywhere.

---

## Data export

Settings → Data & Privacy → "Export Data".

- **Signed in:** nothing is built on the device. `POST /v1/data/export` reads transactions, accounts (including archived) and category budgets, turns each into a CSV, and emails all three as attachments (Resend) to the email on the login; the app shows "Your data is on its way to …" (`backend/src/routes/data.js`). Apple "Hide My Email" users get it at their relay address, which forwards.
- **Guest:** the data is on-device, so the app fetches it fresh through `ApiService` (not the in-memory lists, which may be stale/paginated), serializes each to CSV (`utils/data_export.dart`, pure functions, unit tested), writes them to the OS temp directory, and hands all three files to the native share sheet via `share_plus`. Settings/preferences are deliberately excluded — they're app config, not financial data. CSV was chosen over JSON: the target audience is a non-technical user who wants something that opens in Excel/Sheets, not a re-import format (no import feature exists or is planned).
- **Reset My Account** (Data & Privacy → Danger Zone) is self-service after a confirmation dialog: `DELETE /v1/data` wipes transactions, accounts, categories, budgets and recurring events but keeps the login and `user_settings`; default categories are re-seeded straight after. It is not atomic (see [BACKLOG.md](./BACKLOG.md)).
- **Delete my account** is self-service (signed-in users only): after typing `DELETE`, `DELETE /v1/account` wipes every row (including `user_settings`) and then the Supabase auth user, and the app signs out. If a `user_settings` row survives the wipe (missing DELETE policy), the server keeps the login and returns 500 so nothing is half-deleted silently (`backend/src/routes/account.js`). A failure shows an error and leaves the user signed in to retry.

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
