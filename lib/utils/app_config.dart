/// Compile-time configuration from `--dart-define` (see config.dev.json.example).
class AppConfig {
  AppConfig._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String auth0Domain = String.fromEnvironment('AUTH0_DOMAIN');
  static const String auth0ClientId = String.fromEnvironment('AUTH0_CLIENT_ID');

  /// Custom URL scheme for iOS/macOS Auth0 callbacks (must match Info.plist + Auth0 URLs).
  static const String auth0CallbackScheme = String.fromEnvironment(
    'AUTH0_CALLBACK_SCHEME',
    defaultValue: 'com.shubhamambastha.expensetracker',
  );

  /// Set true only after configuring Associated Domains (webcredentials) in Xcode.
  static const bool auth0UseHttps =
      bool.fromEnvironment('AUTH0_USE_HTTPS', defaultValue: false);

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get hasAuth0 => auth0Domain.isNotEmpty && auth0ClientId.isNotEmpty;
}
