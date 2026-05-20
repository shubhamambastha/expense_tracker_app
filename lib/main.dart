import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'components/common/error_app.dart';
import 'components/common/auth_gate.dart';
import 'services/category_catalog.dart';
import 'services/currency_settings.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Future.wait([
      SupabaseService.init(),
      CurrencySettings.instance.load(),
    ]);
    runApp(const ExpenseTrackerApp());
  } catch (error) {
    runApp(ErrorApp(message: error.toString()));
  }
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        CurrencySettings.instance,
        CategoryCatalog.instance,
      ]),
      builder: (context, _) {
        return MaterialApp(
          title: 'Expense Tracker',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const AuthGate(),
        );
      },
    );
  }
}
