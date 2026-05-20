-- Per-user expense categories (name + icon). Run once in Supabase SQL editor.

CREATE TABLE IF NOT EXISTS public.expense_categories (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  name text NOT NULL,
  icon text NOT NULL DEFAULT 'category_rounded',
  sort_order int NOT NULL DEFAULT 0,
  is_default boolean NOT NULL DEFAULT false,
  inserted_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_expense_categories_user_name
  ON public.expense_categories (user_id, lower(name));

CREATE INDEX IF NOT EXISTS idx_expense_categories_user
  ON public.expense_categories (user_id, sort_order);

ALTER TABLE public.expense_categories ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'expense_categories'
      AND policyname = 'Manage own expense_categories'
  ) THEN
    CREATE POLICY "Manage own expense_categories" ON public.expense_categories
      FOR ALL
      USING (auth.uid() IS NOT NULL AND user_id = auth.uid())
      WITH CHECK (auth.uid() IS NOT NULL AND user_id = auth.uid());
  END IF;
END $$;
