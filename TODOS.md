# TODOS

## Review

### Revive counterparties table + SourcePayerField autofill

**What:** Wire the `counterparties` table and `SourcePayerField` component into the merchant field for autofill/recent-payer suggestions.

**Why:** The Postgres schema (`sql/20260526_counterparties.sql`) and the UI component (`lib/components/transaction/source_payer_field.dart`) already exist, but neither is used anywhere — zero call sites in `lib/`. Real value sitting completely unused.

**Context:** Surfaced during the `/plan-eng-review` for the subscription-picker feature (2026-08-19). This is a separate mechanism from the subscription picker's curated brand catalog — counterparties is meant to be general merchant-history autofill for *any* merchant (Swiggy, a landlord, a friend), not a fixed list of ~25 known brands. Reviving it properly needs its own scoping pass (does `SupabaseService` need new CRUD methods for `counterparties`? does the UI need a redesign since `SourcePayerField` was built speculatively and never integrated?).

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
