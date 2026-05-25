-- =============================================================================
-- Migration: unified `transactions` table
-- Date:      2026-05-26
-- Replaces:  public.expenses (kept intact for safety; drop manually once the
--            app is fully migrated and verified)
-- =============================================================================
--
-- Field → UI mapping
-- ─────────────────────────────────────────────────────────────────────────────
-- kind                   TransactionTypeSelector (expense | income | transfer)
-- amount                 AmountSection (big hero number)
-- currency_code          CurrencyPill under the amount / currency picker sheet
-- category               CategoryPillsSelector (expense) / IncomeCategoryPillsSelector (income)
-- counterparty_name      Details card "Merchant name" (expense)
--                        SourcePayerField "Employer / Client / From …" (income)
-- note                   Details card "Note" field (both modes)
-- account_id             AccountChipsSelector "Account" (expense) /
--                        "Deposit to" (income)
-- transfer_to_account_id AccountChipsSelector "To account" (transfer only)
-- date                   Details card date quick-row (Today / Yesterday / Pick)
-- is_recurring           RecurringPaymentSection toggle
-- recurrence_frequency   RecurringPaymentSection FrequencyWrap chips
--                        (weekly | monthly | quarterly | yearly | custom)
--                        Note: income mode hides 'daily'; daily is allowed in
--                        DB for expense parity — the app filters the UI.
-- recurrence_start_date  RecurringPaymentSection "Start" date picker
-- recurrence_end_date    RecurringPaymentSection "Ends" date picker (optional)
-- reminder_timing        RecurringPaymentSection ReminderWrap chips
-- inserted_at            Server timestamp; never shown in UI directly
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Create the transactions table
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.transactions (
  id                      bigint      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

  -- ownership
  user_id                 uuid        NOT NULL
                            REFERENCES auth.users(id) ON DELETE CASCADE,

  -- what kind of money event is this
  kind                    text        NOT NULL DEFAULT 'expense'
                            CHECK (kind IN ('expense', 'income', 'transfer')),

  -- money
  amount                  numeric(12, 2) NOT NULL
                            CHECK (amount >= 0),
  currency_code           text        NOT NULL DEFAULT 'INR',

  -- categorisation
  -- expense → one of the user's expense_categories.name values
  -- income  → one of the user's income_categories.name values
  -- transfer → optional label / purpose
  category                text,

  -- the other party in the transaction
  -- expense  → merchant name   (e.g. "Zomato", "Netflix")
  -- income   → payer / employer / client  (e.g. "Company XYZ", "Acme Corp")
  -- transfer → free-form label (optional)
  counterparty_name       text,

  -- free-form annotation (Details card "Note" field)
  note                    text,

  -- account that money leaves (expense/transfer) or enters (income)
  account_id              bigint
                            REFERENCES public.accounts(id) ON DELETE SET NULL,

  -- destination account — only meaningful when kind = 'transfer'
  transfer_to_account_id  bigint
                            REFERENCES public.accounts(id) ON DELETE SET NULL,

  -- when the transaction happened (not when it was entered)
  date                    timestamptz NOT NULL,

  -- ── recurring fields ──────────────────────────────────────────────────────
  -- toggled by the RecurringPaymentSection switch
  is_recurring            boolean     NOT NULL DEFAULT false,

  -- weekly | monthly | quarterly | yearly | custom | daily
  -- NULL when is_recurring = false
  recurrence_frequency    text
                            CHECK (recurrence_frequency IN
                              ('daily','weekly','monthly','quarterly','yearly','custom')),

  -- first occurrence date (RecurringPaymentSection "Start" picker)
  recurrence_start_date   timestamptz,

  -- last occurrence date — NULL means "no end date" (runs forever)
  recurrence_end_date     timestamptz,

  -- how early the app reminds the user before the next occurrence
  -- sameDay | oneDayBefore | twoDaysBefore | oneWeekBefore
  -- NULL when is_recurring = false
  reminder_timing         text
                            CHECK (reminder_timing IN
                              ('sameDay','oneDayBefore','twoDaysBefore','oneWeekBefore')),

  -- audit
  inserted_at             timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- 2. Indexes
-- ---------------------------------------------------------------------------

-- primary query pattern: "show my transactions newest first"
CREATE INDEX IF NOT EXISTS idx_transactions_user_date
  ON public.transactions (user_id, date DESC);

-- filter by kind (expenses list, income list, transfers list)
CREATE INDEX IF NOT EXISTS idx_transactions_kind
  ON public.transactions (user_id, kind, date DESC);

-- account ledger view
CREATE INDEX IF NOT EXISTS idx_transactions_account
  ON public.transactions (account_id);

-- look up recurring rows quickly (for reminder processing)
CREATE INDEX IF NOT EXISTS idx_transactions_recurring
  ON public.transactions (user_id, is_recurring)
  WHERE is_recurring = true;

-- ---------------------------------------------------------------------------
-- 3. Row Level Security
-- ---------------------------------------------------------------------------
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename   = 'transactions'
      AND policyname  = 'Insert own transactions'
  ) THEN
    CREATE POLICY "Insert own transactions" ON public.transactions
      FOR INSERT
      WITH CHECK (auth.uid() IS NOT NULL AND user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename   = 'transactions'
      AND policyname  = 'Manage own transactions'
  ) THEN
    CREATE POLICY "Manage own transactions" ON public.transactions
      FOR ALL
      USING (auth.uid() IS NOT NULL AND user_id = auth.uid());
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 4. Back-fill historical data from expenses
--
--    Column mapping:
--      expenses.name         → transactions.counterparty_name
--      expenses.category     → transactions.category
--      expenses.amount       → transactions.amount
--      expenses.date         → transactions.date
--      expenses.account_id   → transactions.account_id
--      expenses.user_id      → transactions.user_id
--      expenses.end_date     → transactions.recurrence_end_date
--      expenses.type         → transactions.is_recurring
--                              (type='recurring' → true, else false)
--      expenses.inserted_at  → transactions.inserted_at
--
--    Fields with no equivalent in expenses (will be NULL / default):
--      currency_code          → defaults to 'INR'
--      kind                   → 'expense'
--      note                   → NULL
--      transfer_to_account_id → NULL
--      recurrence_frequency   → NULL  (old table had no frequency column)
--      recurrence_start_date  → NULL  (old table had no start column)
--      reminder_timing        → NULL
-- ---------------------------------------------------------------------------
INSERT INTO public.transactions (
  user_id,
  kind,
  amount,
  currency_code,
  category,
  counterparty_name,
  account_id,
  date,
  is_recurring,
  recurrence_end_date,
  inserted_at
)
SELECT
  e.user_id,
  'expense'                         AS kind,
  e.amount,
  'INR'                             AS currency_code,
  COALESCE(e.category, 'Other')     AS category,
  e.name                            AS counterparty_name,
  e.account_id,
  e.date,
  (e.type = 'recurring')            AS is_recurring,
  e.end_date                        AS recurrence_end_date,
  e.inserted_at
FROM public.expenses e
WHERE e.user_id IS NOT NULL
  -- skip any row already migrated in a previous run of this script
  AND NOT EXISTS (
    SELECT 1
    FROM public.transactions t
    WHERE t.user_id            = e.user_id
      AND t.counterparty_name  = e.name
      AND t.amount             = e.amount
      AND t.date               = e.date
      AND t.kind               = 'expense'
  );

-- =============================================================================
-- What to do after running this migration
-- =============================================================================
-- 1. Deploy the new Dart Transaction model + SupabaseService.fetchTransactions /
--    insertTransaction / updateTransaction / deleteTransaction methods.
-- 2. Verify the home screen reads from `transactions` correctly.
-- 3. Once confirmed, you can DROP TABLE public.expenses — but do NOT do that
--    in this migration; keep it as a safety net until the app release is stable.
-- =============================================================================
