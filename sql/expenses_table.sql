-- SQL migration for Supabase: create `expenses` table
-- Run this in the SQL editor or as a migration in Supabase

-- If your app is multi-user, include `user_id uuid` to scope rows to users.
CREATE TABLE IF NOT EXISTS public.expenses (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name text NOT NULL,
  category text,
  amount numeric(12,2) NOT NULL DEFAULT 0.0,
  date timestamptz NOT NULL,
  type text NOT NULL,
  end_date timestamptz,
  account_id bigint,
  user_id uuid,
  inserted_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.expenses
ADD COLUMN IF NOT EXISTS account_id bigint;

CREATE TABLE IF NOT EXISTS public.accounts (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name text NOT NULL,
  type text NOT NULL,
  user_id uuid,
  inserted_at timestamptz NOT NULL DEFAULT now()
);

-- INDEXES
CREATE INDEX IF NOT EXISTS idx_expenses_date ON public.expenses (date DESC);
CREATE INDEX IF NOT EXISTS idx_expenses_user ON public.expenses (user_id);
CREATE INDEX IF NOT EXISTS idx_expenses_account ON public.expenses (account_id);
CREATE INDEX IF NOT EXISTS idx_accounts_user ON public.accounts (user_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_accounts_user_name_type
  ON public.accounts (user_id, lower(name), type);

-- Row Level Security example (recommended for multi-user apps)
-- Enable RLS
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
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

-- Allow authenticated users to insert rows where user_id = auth.uid()
CREATE POLICY "Insert own expenses" ON public.expenses
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL AND (user_id = auth.uid() OR user_id IS NULL));

-- Allow authenticated users to select/update/delete their own rows
CREATE POLICY "Manage own expenses" ON public.expenses
  FOR ALL
  USING (auth.uid() IS NOT NULL AND user_id = auth.uid());

CREATE POLICY "Insert own accounts" ON public.accounts
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL AND (user_id = auth.uid() OR user_id IS NULL));

CREATE POLICY "Manage own accounts" ON public.accounts
  FOR ALL
  USING (auth.uid() IS NOT NULL AND user_id = auth.uid());

-- If you want public read access for demo/testing, add a restricted select policy instead of the one above.
