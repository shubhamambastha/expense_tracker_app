-- Normalize expense account storage.
-- Expenses should reference accounts by id only. Account name/type live on accounts.

ALTER TABLE public.expenses
ADD COLUMN IF NOT EXISTS account_id bigint;

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

ALTER TABLE public.expenses
DROP COLUMN IF EXISTS account_name;

ALTER TABLE public.expenses
DROP COLUMN IF EXISTS account_type;
