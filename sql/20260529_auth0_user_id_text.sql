-- Auth0 third-party auth: user_id is Auth0 JWT `sub` (text), not auth.users uuid.
-- Run once on existing databases after enabling Supabase Third-Party Auth0 integration.
--
-- Order matters: policies must be dropped before ALTER COLUMN (Postgres 0A000 otherwise).
-- Skips tables that do not exist (e.g. legacy public.expenses).

-- Helper for RLS policies
CREATE OR REPLACE FUNCTION public.requesting_user_id()
RETURNS text
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT NULLIF(auth.jwt() ->> 'sub', '');
$$;

GRANT EXECUTE ON FUNCTION public.requesting_user_id() TO authenticated, anon;

-- ---------------------------------------------------------------------------
-- 1. Drop all RLS policies on existing app tables (they reference user_id)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  pol RECORD;
  candidate_tables text[] := ARRAY[
    'user_settings',
    'expense_categories',
    'income_categories',
    'transactions',
    'counterparties',
    'category_budgets',
    'recurring_events',
    'accounts',
    'expenses'
  ];
  t text;
BEGIN
  FOREACH t IN ARRAY candidate_tables
  LOOP
    IF NOT EXISTS (
      SELECT 1
      FROM pg_tables
      WHERE schemaname = 'public' AND tablename = t
    ) THEN
      CONTINUE;
    END IF;

    FOR pol IN
      SELECT policyname
      FROM pg_policies
      WHERE schemaname = 'public' AND tablename = t
    LOOP
      EXECUTE format(
        'DROP POLICY IF EXISTS %I ON public.%I',
        pol.policyname,
        t
      );
    END LOOP;
  END LOOP;
END $$;

-- ---------------------------------------------------------------------------
-- 2. Drop foreign keys to auth.users
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT
      c.conrelid::regclass AS table_name,
      c.conname AS constraint_name
    FROM pg_constraint c
    JOIN pg_class rel ON rel.oid = c.conrelid
    JOIN pg_namespace n ON n.oid = rel.relnamespace
    WHERE c.contype = 'f'
      AND n.nspname = 'public'
      AND c.confrelid = 'auth.users'::regclass
  LOOP
    EXECUTE format(
      'ALTER TABLE %s DROP CONSTRAINT IF EXISTS %I',
      r.table_name,
      r.constraint_name
    );
  END LOOP;
END $$;

-- ---------------------------------------------------------------------------
-- 3. Alter user_id columns to text (only on tables that exist)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  t text;
  tables text[] := ARRAY[
    'user_settings',
    'expense_categories',
    'income_categories',
    'transactions',
    'counterparties',
    'category_budgets',
    'recurring_events',
    'accounts',
    'expenses'
  ];
BEGIN
  FOREACH t IN ARRAY tables
  LOOP
    IF NOT EXISTS (
      SELECT 1
      FROM pg_tables
      WHERE schemaname = 'public' AND tablename = t
    ) THEN
      CONTINUE;
    END IF;

    IF NOT EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = t
        AND column_name = 'user_id'
    ) THEN
      CONTINUE;
    END IF;

    EXECUTE format(
      'ALTER TABLE public.%I ALTER COLUMN user_id TYPE text USING user_id::text',
      t
    );
  END LOOP;
END $$;

-- ---------------------------------------------------------------------------
-- 4. Recreate RLS policies (Auth0 sub via requesting_user_id)
-- ---------------------------------------------------------------------------

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_settings') THEN
    CREATE POLICY "Select own user_settings" ON public.user_settings
      FOR SELECT
      USING (
        (SELECT public.requesting_user_id()) IS NOT NULL
        AND user_id = (SELECT public.requesting_user_id())
      );

    CREATE POLICY "Insert own user_settings" ON public.user_settings
      FOR INSERT
      WITH CHECK (
        (SELECT public.requesting_user_id()) IS NOT NULL
        AND user_id = (SELECT public.requesting_user_id())
      );

    CREATE POLICY "Update own user_settings" ON public.user_settings
      FOR UPDATE
      USING (
        (SELECT public.requesting_user_id()) IS NOT NULL
        AND user_id = (SELECT public.requesting_user_id())
      )
      WITH CHECK (
        (SELECT public.requesting_user_id()) IS NOT NULL
        AND user_id = (SELECT public.requesting_user_id())
      );
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'expense_categories') THEN
    CREATE POLICY "Manage own expense_categories" ON public.expense_categories
      FOR ALL
      USING (
        (SELECT public.requesting_user_id()) IS NOT NULL
        AND user_id = (SELECT public.requesting_user_id())
      )
      WITH CHECK (
        (SELECT public.requesting_user_id()) IS NOT NULL
        AND user_id = (SELECT public.requesting_user_id())
      );
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'income_categories') THEN
    CREATE POLICY "Manage own income_categories" ON public.income_categories
      FOR ALL
      USING (
        (SELECT public.requesting_user_id()) IS NOT NULL
        AND user_id = (SELECT public.requesting_user_id())
      )
      WITH CHECK (
        (SELECT public.requesting_user_id()) IS NOT NULL
        AND user_id = (SELECT public.requesting_user_id())
      );
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'transactions') THEN
    CREATE POLICY "Insert own transactions" ON public.transactions
      FOR INSERT
      WITH CHECK (
        (SELECT public.requesting_user_id()) IS NOT NULL
        AND user_id = (SELECT public.requesting_user_id())
      );

    CREATE POLICY "Manage own transactions" ON public.transactions
      FOR ALL
      USING (
        (SELECT public.requesting_user_id()) IS NOT NULL
        AND user_id = (SELECT public.requesting_user_id())
      );
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'counterparties') THEN
    CREATE POLICY "Insert own counterparties" ON public.counterparties
      FOR INSERT
      WITH CHECK (
        (SELECT public.requesting_user_id()) IS NOT NULL
        AND user_id = (SELECT public.requesting_user_id())
      );

    CREATE POLICY "Manage own counterparties" ON public.counterparties
      FOR ALL
      USING (
        (SELECT public.requesting_user_id()) IS NOT NULL
        AND user_id = (SELECT public.requesting_user_id())
      );
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'category_budgets') THEN
    CREATE POLICY "Manage own category_budgets" ON public.category_budgets
      FOR ALL
      USING (
        (SELECT public.requesting_user_id()) IS NOT NULL
        AND user_id = (SELECT public.requesting_user_id())
      )
      WITH CHECK (
        (SELECT public.requesting_user_id()) IS NOT NULL
        AND user_id = (SELECT public.requesting_user_id())
      );
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'recurring_events') THEN
    CREATE POLICY "Insert own recurring events" ON public.recurring_events
      FOR INSERT
      WITH CHECK (
        (SELECT public.requesting_user_id()) IS NOT NULL
        AND user_id = (SELECT public.requesting_user_id())
      );

    CREATE POLICY "Manage own recurring events" ON public.recurring_events
      FOR ALL
      USING (
        (SELECT public.requesting_user_id()) IS NOT NULL
        AND user_id = (SELECT public.requesting_user_id())
      );
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'accounts') THEN
    CREATE POLICY "Insert own accounts" ON public.accounts
      FOR INSERT
      WITH CHECK (
        (SELECT public.requesting_user_id()) IS NOT NULL
        AND (
          user_id = (SELECT public.requesting_user_id())
          OR user_id IS NULL
        )
      );

    CREATE POLICY "Manage own accounts" ON public.accounts
      FOR ALL
      USING (
        (SELECT public.requesting_user_id()) IS NOT NULL
        AND user_id = (SELECT public.requesting_user_id())
      );
  END IF;
END $$;

-- Legacy expenses table (optional — skip if already dropped)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'expenses') THEN
    CREATE POLICY "Insert own expenses" ON public.expenses
      FOR INSERT
      WITH CHECK (
        (SELECT public.requesting_user_id()) IS NOT NULL
        AND (
          user_id = (SELECT public.requesting_user_id())
          OR user_id IS NULL
        )
      );

    CREATE POLICY "Manage own expenses" ON public.expenses
      FOR ALL
      USING (
        (SELECT public.requesting_user_id()) IS NOT NULL
        AND user_id = (SELECT public.requesting_user_id())
      );
  END IF;
END $$;
