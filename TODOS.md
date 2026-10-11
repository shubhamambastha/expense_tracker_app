# TODOS

## Backend API

### Verify the `POST /budgets` upsert target exists in the live DB

**What:** `backend/src/routes/budgets.js` upserts budgets with `onConflict: 'user_id,category_name'`, but the only unique index in `sql/` is `idx_category_budgets_user_category ON (user_id, lower(category_name))`. Postgres can't use an expression index as an `ON CONFLICT (cols)` target, so unless the live DB has an extra plain constraint, every budget save fails with 42P10 (→ 500).

**Why:** The old `SupabaseService.upsertCategoryBudget` used the same target, so this predates the backend. Review couldn't reach the live DB to confirm (connection timeout). If it's broken, budgets and the guest-migration budget replay fail silently.

**Context:** Surfaced by the adversarial review during `/ship` of the Node backend (2026-10-11). Check with `select indexdef from pg_indexes where tablename = 'category_budgets'`. Fix options: a plain `UNIQUE (user_id, category_name)` with names normalised on write, or an upsert RPC.

**Effort:** S
**Priority:** P1
**Depends on:** None.

---

### Enforce foreign-key ownership in Postgres

**What:** `account_id`, `transfer_to_account_id`, `linked_account_id` and `recurring_events.transaction_id` can point at another user's row. FK checks bypass RLS, and sequential ids make 409-vs-201 an existence oracle. Add `UNIQUE (id, user_id)` on `accounts`/`transactions` and switch to composite FKs `(account_id, user_id) → accounts(id, user_id)`. Watch `ON DELETE SET NULL`: use `SET NULL (account_id)` (PG15+) so it doesn't null `user_id`.

**Why:** No victim data is readable, since RLS hides the referenced rows. But one user can attach rows to another user's ids. This belongs in the DB (not the API), because PostgREST is still reachable directly with an Auth0 token.

**Context:** Security specialist + red team during `/ship` of the Node backend (2026-10-11). Existed before the backend.

**Effort:** M
**Priority:** P1
**Depends on:** A migration applied manually per `docs/DATABASE_SCHEMA.md`.

---

### Decide whether to close direct PostgREST access

**What:** Supabase still accepts Auth0 ID tokens directly, and the anon key shipped in earlier builds, so the API's whitelists are advisory. Either revoke table privileges from `anon`/`authenticated` (the API then needs its own DB role or the service-role key), or keep RLS + DB constraints as the enforcement point (the current documented stance in `docs/BACKEND.md`).

**Why:** Switching the backend to the service-role key without first revoking direct access would remove the only enforced guard.

**Effort:** M
**Priority:** P2
**Depends on:** "Enforce foreign-key ownership in Postgres".

---

### Onboarding completion can reset the user's currency to USD

**What:** `markOnboardingComplete()` upserts only `onboarding_completed_at`. For a new user that inserts a `user_settings` row with the DB default `default_currency_code = 'USD'`, which `CurrencySettings.syncForUser` then adopts over the locally chosen currency.

**Why:** Existed before the backend; flagged by adversarial review (2026-10-11). Fix: send the local currency in the same PATCH, or change the column default.

**Effort:** S
**Priority:** P2
**Depends on:** None.

---

### Real-device QA of the API migration

**What:** Manually walk the flows that the automated suite marks as uncovered: login → home loads every resource over real HTTP; an ID token expiring (renew + one retry on 401); guest → sign-in migration and its rollback; what the app shows when the API is down or slow (20s timeout).

**Why:** These need a real device, a real Auth0 login and a running backend, so the coverage gate on the backend PR marked them intentionally uncovered (2026-10-11).

**Effort:** S
**Priority:** P2
**Depends on:** A deployed backend (or a local one on the LAN).

---

### Backend performance and robustness follow-ups

**What:**
- gzip responses (`compression` middleware) unless the host's proxy already does it.
- Parallelize the dashboard's transactions/accounts/budgets fetch (`expense_home_page.dart`) with `Future.wait`.
- Batch guest-migration inserts (array POSTs for transactions/accounts/events) instead of one request per row.
- Idempotency keys on POSTs so a timed-out retry can't duplicate a transaction.
- Make `DELETE /data` atomic via a single Postgres function.
- Set `server.keepAliveTimeout` above the host load balancer's idle timeout.

**Why:** Review findings from `/ship` of the Node backend (2026-10-11). None block launch, and several depend on the chosen host.

**Effort:** M
**Priority:** P3
**Depends on:** Picking a deploy host.

---

## Review

### Swap the Delete Account placeholder support email before release

**What:** `AppInfo.supportEmail` (`lib/config/app_info.dart`) is still the obviously-fake placeholder `support@REPLACE-ME.com` — swap it for the real founder support address before any release build. The Delete Account `mailto:` and its no-mail-app error message both use it.

**Why:** No mechanism in the repo today (no CI grep, no lint rule) stops a build from shipping with the placeholder still in place. This is also the exact mailto: flow `docs/BACKLOG.md`'s "Delete my account" entry flags as relevant to Apple App Store Guideline 5.1.1(v) if this app is ever submitted — a broken/fake destination address on that specific flow is worse than most placeholders.

**Context:** Surfaced by `/plan-eng-review`'s outside-voice pass (2026-08-24) on the Settings IA rebuild. Considered adding an automated CI guard for this instead of a TODO — deliberately chose the lighter, human-tracked option since this is a solo-founder pre-scale app and a CI step felt like more process than the risk currently warrants.

**Effort:** S
**Priority:** P1 (blocks any real release, not blocks-this-PR)
**Depends on:** None (the Delete Account mailto: flow shipped 2026-08-24).

---

### Settings screens widget test coverage

**What:** Widget tests for the rebuilt Settings pages (Profile, Money, Data & Privacy, Support) and specifically the new mailto: deletion-request error path (no mail client installed → `SnackbarHelper.showError`).

**Why:** Zero widget tests exist for any Settings screen today (confirmed — `test/` has no references to any settings page). The `/plan-ceo-review` Settings IA rebuild (2026-08-24) touched every settings file and is a natural moment to have flagged this, but building the suite itself was explicitly deferred to keep that change focused. Matches the general test-coverage gap already tracked in `docs/BACKLOG.md`, scoped specifically to Settings here.

**Effort:** L
**Priority:** P3
**Depends on:** None — unblocked, can start anytime.

---

### Revive counterparties table + SourcePayerField autofill

**What:** Wire the `counterparties` table and `SourcePayerField` component into the merchant field for autofill/recent-payer suggestions.

**Why:** The Postgres schema (`sql/20260526_counterparties.sql`) and the UI component (`lib/components/transaction/source_payer_field.dart`) already exist, but neither is used anywhere — zero call sites in `lib/`. Real value sitting completely unused.

**Context:** Surfaced during the `/plan-eng-review` for the subscription-picker feature (2026-08-19). This is a separate mechanism from the subscription picker's curated brand catalog — counterparties is meant to be general merchant-history autofill for *any* merchant (Swiggy, a landlord, a friend), not a fixed list of ~25 known brands. Reviving it properly needs its own scoping pass (does `counterparties` need a `backend/src/routes/` file plus `ApiService` methods? does the UI need a redesign since `SourcePayerField` was built speculatively and never integrated?).

**Effort:** M
**Priority:** P3
**Depends on:** None

---

### Legal/trademark check before real subscription logos ship

**What:** Before swapping the generated placeholder brand marks in `lib/utils/subscription_catalog.dart` for real official logos (Netflix, Spotify, etc.), do a deliberate check on usage rights.

**Why:** Bundling real trademarked logos as permanent binary assets shipped through app-store review is a different risk profile than an ephemeral runtime fetch — most personal-finance apps (Copilot, Rocket Money, etc.) bundle simplified brand marks under nominative/fair-use for identification purposes, which is likely fine, but it's worth a conscious decision rather than a default, especially before any app-store submission.

**Context:** Surfaced by the outside-voice cross-model review during the `/plan-eng-review` for the subscription-picker feature (2026-08-19). No action needed until the placeholder-to-real-asset swap actually happens.

**Effort:** S
**Priority:** P4
**Depends on:** Real brand-mark assets replacing the generated placeholders

---

### Reconcile subscription auto-detection with the existing Recurring Payments Manager

**What:** Investigate integrating subscription auto-detection and price-change insights with the existing Recurring Payments Manager (`lib/utils/recurring_management.dart`'s `isSubscriptionCategory` category-string classification, `lib/components/recurring/add_recurring_sheet.dart`'s already-working "Add Subscription" flow, `lib/components/recurring/payment_insights_section.dart`'s already-shipped "Subscriptions cost about $X per month" insight) instead of building a parallel catalog/counterparty-name-based classification system.

**Why:** During `/plan-ceo-review` on the subscription-picker feature (2026-08-19), an outside-voice cross-model pass caught that auto-detection, price-change insights, and a proposed Home detection card were designed without ever looking at this existing system. Two independent classification mechanisms (category-string match vs. catalog-name match) would coexist and could disagree about whether a given transaction is "the subscription system." The exclusion rule originally designed for auto-detection ("skip transactions where `isRecurring == true`") would have silently overwritten `counterparty_name` on transactions users already curated through the existing manager. The proposed Home card also duplicated `payment_insights_section.dart`'s existing role.

**Pros:** Prevents shipping a second, occasionally-conflicting subscription-tracking system; likely produces a better-integrated result than either system alone (e.g. extending `isSubscriptionCategory`-based classification with brand-icon lookup, or improving `payment_insights_section.dart` directly instead of adding a third insight-card surface).

**Cons:** Real scoping work before any of auto-detection/price-change/detection-card can resume — not a quick fix.

**Effort:** M
**Priority:** P2
**Depends on:** None — but blocks auto-detection, price-change insights, and the Home detection card specifically. Does not block the baseline picker, retroactive tagging, or onboarding tooltip, which are unaffected by this finding.

---

### Push notification for the proactive insight digest

**What:** Add `flutter_local_notifications` (or equivalent), a persisted 7-day cadence gate, and iOS/Android permission handling so the home-tab insight card can also push a notification, not just render in-app.

**Why:** `docs/designs/proactive-insight-digest.md`'s Approach B scopes v1 as an in-app home-tab card only — no new dependency, cadence is copy-only (live-computed on every app-open, no persisted gate). Push is the explicit fast-follow once the card's insight quality is validated, not a v1 requirement.

**Context:** Surfaced by `/plan-eng-review` (2026-08-28) on the proactive insight digest design. Doubly gated: behind v1 (the home card) shipping, which is itself now gated behind a validation check (see the design doc's Sequencing section — log a week, confirm `generateInsights()` has something meaningful to say, before building anything).

**Effort:** M
**Priority:** P3
**Depends on:** v1 (home-tab insight card) shipping and being validated first; v1 itself depends on the Sequencing validation check in the design doc.
