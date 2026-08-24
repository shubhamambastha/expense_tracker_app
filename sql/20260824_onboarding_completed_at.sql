-- Post-login onboarding wizard completion marker, one per real account.
-- NULL means "onboarding pending" (the standard, unambiguous default) —
-- every row that predates this feature is explicitly backfilled to `now()`
-- below so existing daily users are never gated. A brand-new user's
-- user_settings row is created without this feature ever running, so it
-- naturally starts NULL and correctly sees the wizard once.
-- Run on existing projects after `user_settings_table.sql`.

ALTER TABLE public.user_settings
  ADD COLUMN IF NOT EXISTS onboarding_completed_at timestamptz;

COMMENT ON COLUMN public.user_settings.onboarding_completed_at IS
  'Timestamp the post-login onboarding wizard was completed or skipped. NULL = onboarding pending (shows the wizard).';

-- Backfill: every row that exists at migration time predates this feature
-- and must never be gated.
UPDATE public.user_settings
  SET onboarding_completed_at = now()
  WHERE onboarding_completed_at IS NULL;
