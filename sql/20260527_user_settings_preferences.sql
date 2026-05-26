-- App preferences blob (toggles, enums, limits) synced per user.
-- Run on existing projects after `user_settings_table.sql`.

ALTER TABLE public.user_settings
  ADD COLUMN IF NOT EXISTS preferences jsonb NOT NULL DEFAULT '{}'::jsonb;

COMMENT ON COLUMN public.user_settings.preferences IS
  'JSON map of app settings keys (mirrors SharedPreferences keys used by SettingsPreferences).';
