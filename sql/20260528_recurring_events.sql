-- =============================================================================
-- Migration: per-occurrence recurring events + transaction pause flag
-- Date:      2026-05-28
-- =============================================================================
--
-- Why this migration?
-- ───────────────────
-- The Recurring Payments Manager screen needs to act on individual *occurrences*
-- of a recurring transaction (e.g. "I paid Netflix for May", "skip next month's
-- gym EMI", "snooze the internet bill by 3 days") without losing the schedule
-- itself. The `transactions` table only stores the recurring template — a
-- second table tracks per-occurrence events without bloating the main row.
--
-- It also introduces an `is_paused` column on `transactions` so users can
-- temporarily disable a recurring schedule without deleting it or toggling
-- `is_recurring = false` (which would lose the schedule metadata).
--
-- UI field mapping
-- ────────────────
-- recurring_events.transaction_id   → which recurring schedule this event refers
--                                     to (FK to transactions.id)
-- recurring_events.occurrence_date  → the *scheduled* due date of the occurrence
--                                     the user acted on
-- recurring_events.event_type       → 'paid'    → user logged this occurrence as
--                                                 paid (and the app also inserts
--                                                 a one-time clone transaction)
--                                     'skipped' → user dismissed this occurrence
--                                                 without paying
--                                     'snoozed' → user pushed the reminder out
--                                                 (snooze_until carries the new
--                                                 due date)
-- recurring_events.snooze_until     → only meaningful when event_type='snoozed'
-- transactions.is_paused            → true → recurring schedule is paused; the
--                                            timeline excludes its upcoming
--                                            occurrences until unpaused
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Add the pause flag to transactions
-- ---------------------------------------------------------------------------
ALTER TABLE public.transactions
  ADD COLUMN IF NOT EXISTS is_paused boolean NOT NULL DEFAULT false;

-- Surface paused recurring schedules quickly when computing upcoming payments.
CREATE INDEX IF NOT EXISTS idx_transactions_recurring_active
  ON public.transactions (user_id, is_recurring, is_paused)
  WHERE is_recurring = true;

-- ---------------------------------------------------------------------------
-- 2. recurring_events table
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.recurring_events (
  id              bigint      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

  -- ownership (mirrors transactions for RLS parity)
  user_id         uuid        NOT NULL
                    REFERENCES auth.users(id) ON DELETE CASCADE,

  -- recurring template this event acts on
  transaction_id  bigint      NOT NULL
                    REFERENCES public.transactions(id) ON DELETE CASCADE,

  -- the scheduled occurrence date this event refers to
  occurrence_date date        NOT NULL,

  -- 'paid'    → user marked this occurrence as paid
  -- 'skipped' → user dismissed this occurrence
  -- 'snoozed' → user pushed the reminder to snooze_until
  event_type      text        NOT NULL
                    CHECK (event_type IN ('paid', 'skipped', 'snoozed')),

  -- only set when event_type = 'snoozed'
  snooze_until    date,

  created_at      timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- 3. Indexes
-- ---------------------------------------------------------------------------

-- Primary lookup: "what events exist for this user?" (page load)
CREATE INDEX IF NOT EXISTS idx_recurring_events_user
  ON public.recurring_events (user_id, occurrence_date DESC);

-- Per-transaction lookup: "what has the user done with this schedule?"
CREATE INDEX IF NOT EXISTS idx_recurring_events_transaction
  ON public.recurring_events (transaction_id, occurrence_date DESC);

-- Prevent duplicate events of the same type for the same occurrence
-- (e.g. tapping "Mark paid" twice should be idempotent on the event side).
CREATE UNIQUE INDEX IF NOT EXISTS idx_recurring_events_unique_occurrence
  ON public.recurring_events
     (user_id, transaction_id, occurrence_date, event_type);

-- ---------------------------------------------------------------------------
-- 4. Row Level Security
-- ---------------------------------------------------------------------------
ALTER TABLE public.recurring_events ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename   = 'recurring_events'
      AND policyname  = 'Insert own recurring events'
  ) THEN
    CREATE POLICY "Insert own recurring events" ON public.recurring_events
      FOR INSERT
      WITH CHECK (auth.uid() IS NOT NULL AND user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename   = 'recurring_events'
      AND policyname  = 'Manage own recurring events'
  ) THEN
    CREATE POLICY "Manage own recurring events" ON public.recurring_events
      FOR ALL
      USING (auth.uid() IS NOT NULL AND user_id = auth.uid());
  END IF;
END $$;

-- =============================================================================
-- Dart integration notes
-- =============================================================================
-- 1. SupabaseService gains:
--      fetchRecurringEvents()        → List<RecurringEvent>
--      insertRecurringEvent(event)   → RecurringEvent (with id)
--      deleteRecurringEvent(id)      → void
--      setTransactionPaused(id, bool)→ Transaction
--
-- 2. Mark paid flow inserts both:
--      a) a one-time Transaction clone (isRecurring=false, date=now)
--      b) a 'paid' RecurringEvent for the scheduled occurrence_date
--    Undo deletes both rows.
--
-- 3. The Dart helper `nextDueWithEvents` skips occurrence_dates that already
--    have 'paid' or 'skipped' events, and shifts 'snoozed' occurrences to
--    snooze_until, then continues stepping forward by frequency.
-- =============================================================================
