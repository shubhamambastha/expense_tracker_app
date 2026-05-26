-- Per-user preferences (default currency). Run once in Supabase SQL editor.

CREATE TABLE IF NOT EXISTS public.user_settings (
  user_id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  default_currency_code text NOT NULL DEFAULT 'USD',
  preferences jsonb NOT NULL DEFAULT '{}'::jsonb,
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'user_settings'
      AND policyname = 'Select own user_settings'
  ) THEN
    CREATE POLICY "Select own user_settings" ON public.user_settings
      FOR SELECT
      USING (auth.uid() IS NOT NULL AND user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'user_settings'
      AND policyname = 'Insert own user_settings'
  ) THEN
    CREATE POLICY "Insert own user_settings" ON public.user_settings
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
      AND tablename = 'user_settings'
      AND policyname = 'Update own user_settings'
  ) THEN
    CREATE POLICY "Update own user_settings" ON public.user_settings
      FOR UPDATE
      USING (auth.uid() IS NOT NULL AND user_id = auth.uid())
      WITH CHECK (auth.uid() IS NOT NULL AND user_id = auth.uid());
  END IF;
END $$;
