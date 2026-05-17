-- Add named accounts and link expenses to them.
-- Run this once in Supabase SQL editor or as a migration.

CREATE TABLE IF NOT EXISTS public.accounts (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name text NOT NULL,
  type text NOT NULL,
  user_id uuid,
  inserted_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.expenses
ADD COLUMN IF NOT EXISTS account_id bigint;

CREATE INDEX IF NOT EXISTS idx_accounts_user ON public.accounts (user_id);
CREATE INDEX IF NOT EXISTS idx_expenses_account ON public.expenses (account_id);

CREATE UNIQUE INDEX IF NOT EXISTS idx_accounts_user_name_type
  ON public.accounts (user_id, lower(name), type);

ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'expenses_account_id_fkey'
  ) THEN
    ALTER TABLE public.expenses
    ADD CONSTRAINT expenses_account_id_fkey
    FOREIGN KEY (account_id)
    REFERENCES public.accounts(id)
    ON DELETE SET NULL;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'accounts'
      AND policyname = 'Insert own accounts'
  ) THEN
    CREATE POLICY "Insert own accounts" ON public.accounts
      FOR INSERT
      WITH CHECK (auth.uid() IS NOT NULL AND user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'accounts'
      AND policyname = 'Manage own accounts'
  ) THEN
    CREATE POLICY "Manage own accounts" ON public.accounts
      FOR ALL
      USING (auth.uid() IS NOT NULL AND user_id = auth.uid());
  END IF;
END $$;
