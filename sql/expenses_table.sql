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
  account_type text,
  user_id uuid,
  inserted_at timestamptz NOT NULL DEFAULT now()
);

-- INDEXES
CREATE INDEX IF NOT EXISTS idx_expenses_date ON public.expenses (date DESC);
CREATE INDEX IF NOT EXISTS idx_expenses_user ON public.expenses (user_id);

-- Row Level Security example (recommended for multi-user apps)
-- Enable RLS
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to insert rows where user_id = auth.uid()
CREATE POLICY "Insert own expenses" ON public.expenses
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL AND (user_id = auth.uid() OR user_id IS NULL));

-- Allow authenticated users to select/update/delete their own rows
CREATE POLICY "Manage own expenses" ON public.expenses
  FOR ALL
  USING (auth.uid() IS NOT NULL AND user_id = auth.uid());

-- If you want public read access for demo/testing, add a restricted select policy instead of the one above.
