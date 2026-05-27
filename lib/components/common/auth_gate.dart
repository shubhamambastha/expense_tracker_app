import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/design_tokens.dart';
import '../../screens/auth/login_page.dart';
import '../../screens/home/expense_home_page.dart';
import '../../services/category_budget_service.dart';
import '../../services/category_catalog.dart';
import '../../services/income_category_catalog.dart';
import '../../services/currency_settings.dart';
import '../../services/settings_preferences.dart';
import '../../services/supabase_service.dart';

/// Gate that handles auth state and routes to appropriate screen
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isInitializing = true;
  User? _user;
  StreamSubscription<dynamic>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _user = SupabaseService.currentUser;
    _authSubscription = SupabaseService.authStateChanges.listen(_onAuthStateChange);
    _finishInitialization();
  }

  void _onAuthStateChange(dynamic _) {
    final user = SupabaseService.currentUser;
    if (user != null) {
      unawaited(_syncUserPreferences(user.id));
    } else {
      CurrencySettings.instance.onSignedOut();
      SettingsPreferences.instance.onSignedOut();
      CategoryCatalog.instance.onSignedOut();
      IncomeCategoryCatalog.instance.onSignedOut();
      CategoryBudgetService.instance.onSignedOut();
    }
    setState(() => _user = user);
  }

  Future<void> _finishInitialization() async {
    final user = SupabaseService.currentUser;
    if (user != null) {
      await _syncUserPreferences(user.id);
    }
    if (!mounted) return;
    setState(() {
      _isInitializing = false;
      _user = user;
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _syncUserPreferences(String userId) async {
    await CurrencySettings.instance.syncForUser(userId);
    await SettingsPreferences.instance.syncForUser(userId);
    await CategoryCatalog.instance.syncForUser(userId);
    await IncomeCategoryCatalog.instance.syncForUser(userId);
    await CategoryBudgetService.instance.refresh();
  }

  Future<void> _signOut() async {
    await SupabaseService.signOut();
    CurrencySettings.instance.onSignedOut();
    SettingsPreferences.instance.onSignedOut();
    CategoryCatalog.instance.onSignedOut();
    IncomeCategoryCatalog.instance.onSignedOut();
    CategoryBudgetService.instance.onSignedOut();
    if (!mounted) return;
    setState(() {
      _user = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    if (_user == null) {
      return LoginPage(
        onSignedIn: () async {
          final user = SupabaseService.currentUser;
          if (user != null) {
            await _syncUserPreferences(user.id);
          }
          if (!mounted) return;
          setState(() => _user = user);
        },
      );
    }

    return ExpenseHomePage(onSignOut: _signOut);
  }
}
