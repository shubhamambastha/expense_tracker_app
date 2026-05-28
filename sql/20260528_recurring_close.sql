-- =============================================================================
-- Migration: terminal "closed" state for recurring transactions
-- Date:      2026-05-28
-- =============================================================================
--
-- Why this migration?
-- ───────────────────
-- The Recurring Payments Manager needs a way to *terminate* a recurring
-- schedule (the user cancelled their Netflix subscription, pre-paid an EMI,
-- or ended a rent contract) without deleting the underlying transaction row.
--
-- `is_paused` (added in 20260528_recurring_events.sql) is a *reversible*
-- "snooze the schedule" flag. `closed_at` is the *irreversible* (well, can
-- be cleared via Undo within a short window) "this schedule is done" flag.
--
-- A single nullable timestamp column covers all three verbs the UI exposes:
--   subscription → "Cancel subscription"
--   emi          → "Mark as completed"
--   other        → "Close schedule"
-- The UI picks the right verb based on the transaction's category; the
-- database doesn't need to distinguish.
--
-- UI field mapping
-- ────────────────
-- transactions.closed_at   → NULL → schedule is open
--                           → non-NULL → schedule is closed; excluded from
--                             the upcoming-payments timeline AND from every
--                             section card on the Recurring Payments Manager
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Add the closed_at column
-- ---------------------------------------------------------------------------
ALTER TABLE public.transactions
  ADD COLUMN IF NOT EXISTS closed_at timestamptz;

-- ---------------------------------------------------------------------------
-- 2. Index for "active recurring schedules" lookups
--    (used implicitly by the manager screen which filters out closed rows)
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_transactions_recurring_open
  ON public.transactions (user_id, is_recurring, is_paused, closed_at)
  WHERE is_recurring = true AND closed_at IS NULL;

-- =============================================================================
-- Dart integration notes
-- =============================================================================
-- 1. SupabaseService gains:
--      setTransactionClosed(id, closed: bool) → Transaction
--    `closed: true`  sets closed_at = now()
--    `closed: false` sets closed_at = NULL (Undo within snackbar window)
--
-- 2. RecurringManagement.nextDueWithEvents now returns null for
--    `closed_at != null` schedules in addition to the existing paused check.
--
-- 3. RecurringManagement.build skips closed schedules entirely so they
--    disappear from the manager's Upcoming timeline AND each section card.
-- =============================================================================
