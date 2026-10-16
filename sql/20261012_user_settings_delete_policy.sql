-- user_settings had SELECT/INSERT/UPDATE policies but no DELETE, so a user-scoped delete matched
-- 0 rows without an error. DELETE /v1/account needs it; apply BEFORE deploying the Supabase Auth backend
-- (the route refuses to delete the login while a user_settings row survives).

DROP POLICY IF EXISTS "Delete own user_settings" ON public.user_settings;

CREATE POLICY "Delete own user_settings" ON public.user_settings
  FOR DELETE
  USING (
    (SELECT public.requesting_user_id()) IS NOT NULL
    AND user_id = (SELECT public.requesting_user_id())
  );
