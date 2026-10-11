-- Index + RLS tidy-up from the pre-deploy performance pass (Supabase advisors + API query review).
-- Safe to re-run. Every statement is idempotent.

-- 1. BUG FIX: POST /v1/budgets upserts ON CONFLICT (user_id, category_name), but the only unique
--    index was on lower(category_name), and Postgres won't infer that, so every upsert failed with 42P10.
--    The lower() index stays, so names remain unique case-insensitively.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'category_budgets_user_category_key') THEN
    ALTER TABLE public.category_budgets
      ADD CONSTRAINT category_budgets_user_category_key UNIQUE (user_id, category_name);
  END IF;
END $$;

-- 2. Cover the two unindexed FKs. Without these, deleting an account seq-scans every user's rows to
--    run ON DELETE SET NULL. Partial, because almost every row is NULL here.
CREATE INDEX IF NOT EXISTS idx_transactions_transfer_to_account
  ON public.transactions (transfer_to_account_id) WHERE transfer_to_account_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_accounts_linked_account
  ON public.accounts (linked_account_id) WHERE linked_account_id IS NOT NULL;

-- 3. Drop indexes no query uses. The API filters only on user_id, and recurring/kind filtering happens
--    client-side. The (user_id) ones are covered by wider indexes that lead with user_id. Each spare
--    index costs every write.
DROP INDEX IF EXISTS public.idx_accounts_user;                 -- covered by idx_accounts_user_archived
DROP INDEX IF EXISTS public.idx_category_budgets_user;         -- covered by idx_category_budgets_user_category
DROP INDEX IF EXISTS public.idx_transactions_kind;
DROP INDEX IF EXISTS public.idx_transactions_recurring;
DROP INDEX IF EXISTS public.idx_transactions_recurring_active;
DROP INDEX IF EXISTS public.idx_transactions_recurring_open;

-- 4. Drop the separate INSERT policies. Each table's FOR ALL "Manage own …" policy already applies its
--    USING clause as the INSERT check, so every insert was paying for two policies.
--    On accounts this also closes the `OR user_id IS NULL` hole, which allowed orphan rows.
DROP POLICY IF EXISTS "Insert own accounts" ON public.accounts;
DROP POLICY IF EXISTS "Insert own transactions" ON public.transactions;
DROP POLICY IF EXISTS "Insert own counterparties" ON public.counterparties;
DROP POLICY IF EXISTS "Insert own recurring events" ON public.recurring_events;
