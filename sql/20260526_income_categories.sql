-- =============================================================================
-- Migration: per-user income categories
-- Date:      2026-05-26
--
-- Why a separate table from expense_categories?
-- ─────────────────────────────────────────────
-- Expense and income categories serve different UX flows with different icons
-- and labels.  Keeping them in separate tables means:
--   • Simple queries — no need for a `scope` filter on every read.
--   • The IncomeCategoryPillsSelector and CategoryPillsSelector never see each
--     other's rows.
--   • Users can customise income categories independently (future feature).
--
-- Structure is intentionally identical to expense_categories so the Dart
-- service layer can be trivially extended (same fromMap / toMap pattern).
--
-- UI field mapping
-- ────────────────
-- name       → IncomeCategoryPillsSelector pill label
-- icon       → CategoryIcons.iconForKey(icon) — same icon map used for expenses
-- sort_order → determines pill order; recently-used bubbling is done in Dart
-- is_default → true for the 8 seeds below; false for user-created categories
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Table
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.income_categories (
  id          bigint      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id     uuid        NOT NULL
                REFERENCES auth.users(id) ON DELETE CASCADE,
  name        text        NOT NULL,
  icon        text        NOT NULL DEFAULT 'savings_rounded',
  sort_order  int         NOT NULL DEFAULT 0,
  is_default  boolean     NOT NULL DEFAULT false,
  inserted_at timestamptz NOT NULL DEFAULT now()
);

-- one category name per user (case-insensitive)
CREATE UNIQUE INDEX IF NOT EXISTS idx_income_categories_user_name
  ON public.income_categories (user_id, lower(name));

-- ordered fetch
CREATE INDEX IF NOT EXISTS idx_income_categories_user
  ON public.income_categories (user_id, sort_order);

-- ---------------------------------------------------------------------------
-- 2. Row Level Security
-- ---------------------------------------------------------------------------
ALTER TABLE public.income_categories ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename   = 'income_categories'
      AND policyname  = 'Manage own income_categories'
  ) THEN
    CREATE POLICY "Manage own income_categories" ON public.income_categories
      FOR ALL
      USING      (auth.uid() IS NOT NULL AND user_id = auth.uid())
      WITH CHECK (auth.uid() IS NOT NULL AND user_id = auth.uid());
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 3. Default seed data
--
--    Mirrors IncomeCategoryCatalog.categories in Dart
--    (lib/services/income_category_catalog.dart).
--
--    This INSERT seeds defaults for *existing* users at migration time.
--    New users are seeded at sign-in via ensureDefaultIncomeCategories()
--    (same pattern as ensureDefaultCategories for expenses).
--
--    Icon keys map to CategoryIcons.pickerOptions in
--    lib/utils/category_style.dart.
-- ---------------------------------------------------------------------------
INSERT INTO public.income_categories (user_id, name, icon, sort_order, is_default)
SELECT
  u.id                 AS user_id,
  seed.name            AS name,
  seed.icon            AS icon,
  seed.sort_order      AS sort_order,
  true                 AS is_default
FROM auth.users u
CROSS JOIN (
  VALUES
    ('Salary',      'work_rounded',         0),
    ('Freelance',   'work_rounded',         1),
    ('Refund',      'receipt_rounded',      2),
    ('Bonus',       'savings_rounded',      3),
    ('Gift',        'card_giftcard_rounded', 4),
    ('Cashback',    'savings_rounded',      5),
    ('Investment',  'savings_rounded',      6),
    ('Rental',      'home_rounded',         7)
) AS seed(name, icon, sort_order)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.income_categories ic
  WHERE ic.user_id = u.id
    AND lower(ic.name) = lower(seed.name)
);

-- =============================================================================
-- Dart integration notes
-- =============================================================================
-- Add to SupabaseService:
--
--   static Future<List<IncomeCategory>> fetchIncomeCategories() async { … }
--   static Future<List<IncomeCategory>> ensureDefaultIncomeCategories() async { … }
--   static Future<IncomeCategory> insertIncomeCategory({…}) async { … }
--   static Future<void> deleteIncomeCategory(int id) async { … }
--
-- Then wire IncomeCategoryCatalog.syncForUser() like CategoryCatalog.syncForUser()
-- so pills render from the DB instead of the hard-coded list.
-- =============================================================================
