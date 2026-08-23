import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../components/auth/login_form.dart';
import '../../components/common/compact_header.dart';
import '../../config/design_tokens.dart';
import '../../services/auth_service.dart';
import '../../utils/snackbar_helper.dart';

/// Auth0 Universal Login screen.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() => _isLoading = true);

    try {
      await AuthService.instance.login();
      // AuthGate's session listener takes it from here (syncs user data,
      // then switches phases) — stay loading until this page is replaced.
    } on AuthLoginCancelledException {
      if (mounted) setState(() => _isLoading = false);
    } catch (error) {
      if (!mounted) return;
      SnackbarHelper.showError(context, error);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const CompactHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.xxxl,
                AppSpacing.xxl,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Welcome back',
                    style: AppTextStyles.displaySmall,
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(duration: AppDurations.page)
                      .slideY(begin: 0.08, end: 0),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Track expenses across devices',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(
                        duration: AppDurations.page,
                        delay: const Duration(milliseconds: 80),
                      ),
                  const SizedBox(height: AppSpacing.xxxl),
                  LoginForm(
                    isLoading: _isLoading,
                    onSignIn: _signIn,
                  )
                      .animate()
                      .fadeIn(
                        duration: AppDurations.page,
                        delay: const Duration(milliseconds: 120),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
