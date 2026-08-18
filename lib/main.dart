import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/design_tokens.dart';
import 'config/theme.dart';
import 'components/common/error_app.dart';
import 'components/common/auth_gate.dart';
import 'services/category_catalog.dart';
import 'services/currency_settings.dart';
import 'services/settings_preferences.dart';
import 'services/deep_link_service.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Future.wait([
      SupabaseService.init(),
      CurrencySettings.instance.load(),
      SettingsPreferences.instance.load(),
    ]);
    _applyTheme();
    unawaited(DeepLinkService.instance.start());
    runApp(const ExpenseTrackerApp());
  } catch (error) {
    runApp(ErrorApp(message: error.toString()));
  }
}

/// Pushes [SettingsPreferences]'s theme/accent choice into [AppColors] and
/// the system status/nav bar. Call before building anything that reads
/// [AppColors] — once at startup and again on every rebuild the theme could
/// have changed in.
void _applyTheme() {
  final prefs = SettingsPreferences.instance;
  AppColors.configure(
    brightness: prefs.themeMode == ThemeMode.light
        ? Brightness.light
        : Brightness.dark,
    accent: prefs.accentColor,
  );
  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemOverlay);
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        CurrencySettings.instance,
        CategoryCatalog.instance,
        SettingsPreferences.instance,
      ]),
      builder: (context, _) {
        _applyTheme();
        final themeMode = SettingsPreferences.instance.themeMode;
        final theme = themeMode == ThemeMode.light
            ? AppTheme.lightTheme
            : AppTheme.darkTheme;
        return MaterialApp(
          title: 'Expense Tracker',
          debugShowCheckedModeBanner: false,
          theme: theme,
          darkTheme: theme,
          themeMode: themeMode,
          home: const AuthGate(),
        );
      },
    );
  }
}
