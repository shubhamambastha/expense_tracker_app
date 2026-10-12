-- Auth0 → Supabase Auth cutover (pre-launch): drop rows owned by Auth0 users.
-- Supabase user ids are UUIDs; Auth0 subs always contain '|' (auth0|…, google-oauth2|…, apple|…).
-- Run once, manually, after the Supabase Auth build is verified and the Third-Party Auth0
-- integration is turned off. Nothing to remap: there were no real users yet.
-- Children before parents so FKs never block a delete; skips tables that don't exist.
--
-- IRREVERSIBLE. Take a backup first (Database → Backups, or `supabase db dump`), then preview:
--   SELECT 'transactions' AS t, count(*) FROM public.transactions WHERE user_id LIKE '%|%'
--   UNION ALL SELECT 'accounts', count(*) FROM public.accounts WHERE user_id LIKE '%|%'
--   UNION ALL SELECT 'user_settings', count(*) FROM public.user_settings WHERE user_id LIKE '%|%';
-- Rows written under pre-2026-05-29 Supabase UUIDs are kept on purpose; to also clear orphans
-- with no matching auth user, add: OR user_id NOT IN (SELECT id::text FROM auth.users).

DO $$
DECLARE
  t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'recurring_events', 'transactions', 'accounts', 'category_budgets',
    'expense_categories', 'income_categories', 'counterparties', 'user_settings', 'expenses'
  ]
  LOOP
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = t) THEN
      EXECUTE format('DELETE FROM public.%I WHERE user_id::text LIKE %L', t, '%|%');
    END IF;
  END LOOP;
END $$;
