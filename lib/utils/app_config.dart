/// Compile-time configuration from `--dart-define` (see config.dev.json.example).
class AppConfig {
  AppConfig._();

  /// Base URL of the Node API in `backend/`, without a trailing slash
  /// (e.g. `http://localhost:3000`).
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Supabase project used for sign-in only. All data still goes through
  /// the API; the publishable key is safe to ship because RLS guards the rows.
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  /// Google Cloud OAuth clients. The Web client is what Supabase verifies the
  /// ID token against; the iOS client is what the native sheet signs in with.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );
  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );

  static bool get hasApi => apiBaseUrl.isNotEmpty;

  /// Without the Web client the Google sheet can't produce an ID token.
  static bool get hasGoogle => googleWebClientId.isNotEmpty;

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
