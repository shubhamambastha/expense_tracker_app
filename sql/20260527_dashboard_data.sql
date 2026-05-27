-- Dashboard data layer: account balance / credit fields + per-user category
-- budgets. Mirrors the patterns used by previous migrations
-- (sql/20260517_add_named_accounts.sql, sql/expense_categories_table.sql).

ALTER TABLE public.accounts
ADD COLUMN IF NOT EXISTS opening_balance numeric(14,2) NOT NULL DEFAULT 0;

ALTER TABLE public.accounts
ADD COLUMN IF NOT EXISTS credit_limit numeric(14,2);

ALTER TABLE public.accounts
ADD COLUMN IF NOT EXISTS statement_day smallint;

ALTER TABLE public.accounts
ADD COLUMN IF NOT EXISTS due_day smallint;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'accounts_statement_day_range'
  ) THEN
    ALTER TABLE public.accounts
    ADD CONSTRAINT accounts_statement_day_range
    CHECK (statement_day IS NULL OR (statement_day BETWEEN 1 AND 31));
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'accounts_due_day_range'
  ) THEN
    ALTER TABLE public.accounts
    ADD CONSTRAINT accounts_due_day_range
    CHECK (due_day IS NULL OR (due_day BETWEEN 1 AND 31));
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.category_budgets (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  category_name text NOT NULL,
  monthly_limit numeric(14,2) NOT NULL,
  currency_code text NOT NULL DEFAULT 'INR',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_category_budgets_user_category
  ON public.category_budgets (user_id, lower(category_name));

CREATE INDEX IF NOT EXISTS idx_category_budgets_user
  ON public.category_budgets (user_id);

ALTER TABLE public.category_budgets ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'category_budgets'
      AND policyname = 'Manage own category_budgets'
  ) THEN
    CREATE POLICY "Manage own category_budgets" ON public.category_budgets
      FOR ALL
      USING (auth.uid() IS NOT NULL AND user_id = auth.uid())
      WITH CHECK (auth.uid() IS NOT NULL AND user_id = auth.uid());
  END IF;
END $$;
