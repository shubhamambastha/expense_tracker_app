import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../screens/auth/login_page.dart';
import '../../screens/home/expense_home_page.dart';
import '../../services/currency_settings.dart';
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
      unawaited(CurrencySettings.instance.syncForUser(user.id));
    } else {
      CurrencySettings.instance.onSignedOut();
    }
    setState(() => _user = user);
  }

  Future<void> _finishInitialization() async {
    final user = SupabaseService.currentUser;
    if (user != null) {
      await CurrencySettings.instance.syncForUser(user.id);
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

  Future<void> _signOut() async {
    await SupabaseService.signOut();
    CurrencySettings.instance.onSignedOut();
    if (!mounted) return;
    setState(() {
      _user = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return LoginPage(
        onSignedIn: () async {
          final user = SupabaseService.currentUser;
          if (user != null) {
            await CurrencySettings.instance.syncForUser(user.id);
          }
          if (!mounted) return;
          setState(() => _user = user);
        },
      );
    }

    return ExpenseHomePage(onSignOut: _signOut);
  }
}
