-- =============================================================================
-- Migration: counterparties (payer / merchant autofill history)
-- Date:      2026-05-26
--
-- Why this table?
-- ───────────────
-- The SourcePayerField (income mode) and the merchant field (expense mode)
-- both benefit from autofill.  Two sources feed this:
--
--   A. Derived  — every saved transaction's counterparty_name is a free-form
--      string.  The app can GROUP BY counterparty_name to build recent-payer
--      lists without any extra table.  This is fine for "recently used" chips.
--
--   B. Pinned   — users may want to save a payer permanently (e.g. "Company XYZ"
--      as their permanent employer) so it always appears in the quick-pick list
--      even if they haven't logged that income in a while.  This needs a table.
--
-- This table covers case B.  Case A continues to work from the transactions
-- table query; the Dart service can union both sources before ranking.
--
-- UI field mapping
-- ────────────────
-- name         → SourcePayerField recent-payer chips
--                Details card "Merchant name" (expense) autofill
-- kind         → which mode's pill list this name appears in
--                'merchant' → expense mode counterparty chips
--                'employer' → income Salary payer chips
--                'client'   → income Freelance payer chips
--                'person'   → income Gift / Cashback payer chips
--                'generic'  → shown in all income categories
-- last_used_at → used to sort / rank suggestions (most-recent first)
-- use_count    → secondary sort signal for tie-breaking (future AI ranking)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Table
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.counterparties (
  id           bigint      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id      uuid        NOT NULL
                 REFERENCES auth.users(id) ON DELETE CASCADE,

  -- The display name shown in the chip (e.g. "Company XYZ", "Amazon")
  name         text        NOT NULL,

  -- Contextual kind so the app can filter chips by current mode / category
  -- merchant → expense merchant chips
  -- employer → income Salary payer field
  -- client   → income Freelance payer field
  -- person   → income Gift / Cashback "From" field
  -- generic  → shown across all income category payer fields
  kind         text        NOT NULL DEFAULT 'generic'
                 CHECK (kind IN ('merchant','employer','client','person','generic')),

  -- Signals for ranking in autofill (updated whenever a transaction is saved
  -- with this counterparty name)
  use_count    int         NOT NULL DEFAULT 1,
  last_used_at timestamptz NOT NULL DEFAULT now(),

  inserted_at  timestamptz NOT NULL DEFAULT now()
);

-- one row per (user, name, kind) — prevent duplicates
CREATE UNIQUE INDEX IF NOT EXISTS idx_counterparties_user_name_kind
  ON public.counterparties (user_id, lower(name), kind);

-- fast lookup for the autofill query: recent + frequent per kind
CREATE INDEX IF NOT EXISTS idx_counterparties_user_kind_rank
  ON public.counterparties (user_id, kind, last_used_at DESC, use_count DESC);

-- ---------------------------------------------------------------------------
-- 2. Row Level Security
-- ---------------------------------------------------------------------------
ALTER TABLE public.counterparties ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename   = 'counterparties'
      AND policyname  = 'Insert own counterparties'
  ) THEN
    CREATE POLICY "Insert own counterparties" ON public.counterparties
      FOR INSERT
      WITH CHECK (auth.uid() IS NOT NULL AND user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename   = 'counterparties'
      AND policyname  = 'Manage own counterparties'
  ) THEN
    CREATE POLICY "Manage own counterparties" ON public.counterparties
      FOR ALL
      USING (auth.uid() IS NOT NULL AND user_id = auth.uid());
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 3. Back-fill from historical expense data
--
--    Populates 'merchant' kind rows from existing expenses.name values so
--    the autofill chips are immediately populated for existing users.
-- ---------------------------------------------------------------------------
INSERT INTO public.counterparties (user_id, name, kind, use_count, last_used_at)
SELECT
  e.user_id,
  e.name                        AS name,
  'merchant'                    AS kind,
  count(*)::int                 AS use_count,
  max(e.date)                   AS last_used_at
FROM public.expenses e
WHERE e.user_id IS NOT NULL
  AND e.name IS NOT NULL
  AND trim(e.name) <> ''
GROUP BY e.user_id, e.name
ON CONFLICT (user_id, lower(name), kind)
DO UPDATE SET
  use_count    = EXCLUDED.use_count,
  last_used_at = EXCLUDED.last_used_at;

-- =============================================================================
-- Dart integration notes
-- =============================================================================
-- 1. On transaction save (insertTransaction), upsert into counterparties:
--
--      INSERT INTO counterparties (user_id, name, kind, use_count, last_used_at)
--      VALUES ($1, $2, $3, 1, now())
--      ON CONFLICT (user_id, lower(name), kind)
--      DO UPDATE SET
--        use_count    = counterparties.use_count + 1,
--        last_used_at = now();
--
-- 2. Autofill query (merge pinned + derived):
--
--      -- Pinned (user explicitly saved or use_count > 1):
--      SELECT name FROM counterparties
--      WHERE user_id = $1 AND kind = $2
--      ORDER BY last_used_at DESC, use_count DESC
--      LIMIT 8;
--
--      -- Derived (from transaction history, for categories with no pins yet):
--      SELECT counterparty_name AS name, max(date) AS last_used_at
--      FROM transactions
--      WHERE user_id = $1 AND kind = $2 AND counterparty_name IS NOT NULL
--      GROUP BY counterparty_name
--      ORDER BY last_used_at DESC
--      LIMIT 8;
--
-- 3. SourcePayerField passes the merged list as `recentPayers` to the widget.
--
-- 4. kind mapping (matches IncomeFlowHelpers.payerFieldLabel):
--    category = Salary      → kind = 'employer'
--    category = Freelance   → kind = 'client'
--    category = Gift        → kind = 'person'
--    category = Cashback    → kind = 'person'
--    category = Refund / Bonus / Investment / Rental → kind = 'generic'
--    expense mode           → kind = 'merchant'
-- =============================================================================
