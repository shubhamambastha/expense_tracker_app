-- Accounts management: metadata, archive, linked sources, wallet providers.

ALTER TABLE public.accounts
ADD COLUMN IF NOT EXISTS nickname text;

ALTER TABLE public.accounts
ADD COLUMN IF NOT EXISTS provider_name text;

ALTER TABLE public.accounts
ADD COLUMN IF NOT EXISTS notes text;

ALTER TABLE public.accounts
ADD COLUMN IF NOT EXISTS is_archived boolean NOT NULL DEFAULT false;

ALTER TABLE public.accounts
ADD COLUMN IF NOT EXISTS linked_account_id bigint
  REFERENCES public.accounts(id) ON DELETE SET NULL;

ALTER TABLE public.accounts
ADD COLUMN IF NOT EXISTS wallet_provider text;

CREATE INDEX IF NOT EXISTS idx_accounts_user_archived
  ON public.accounts (user_id, is_archived);
