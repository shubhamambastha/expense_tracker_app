import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'components/common/error_app.dart';
import 'components/common/auth_gate.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SupabaseService.init();
    runApp(const ExpenseTrackerApp());
  } catch (error) {
    runApp(ErrorApp(message: error.toString()));
  }
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}
