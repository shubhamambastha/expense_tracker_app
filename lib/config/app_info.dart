/// App version, kept in sync with the `version:` line in pubspec.yaml.
///
/// Single source so the Settings hub and About page can't drift apart.
class AppInfo {
  AppInfo._();

  static const String version = '1.0.0';
  static const String buildNumber = '1';
  static const String versionLabel = 'v$version ($buildNumber)';

  /// PLACEHOLDER — swap for the real support inbox before any release build.
  /// Tracked in TODOS.md ("Swap the Delete Account placeholder support
  /// email before release") since nothing in the repo enforces this today.
  static const String supportEmail = 'support@REPLACE-ME.com';
}
