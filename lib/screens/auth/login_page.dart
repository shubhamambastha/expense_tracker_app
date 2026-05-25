import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../components/auth/login_form.dart';
import '../../components/common/compact_header.dart';
import '../../config/design_tokens.dart';
import '../../services/supabase_service.dart';
import '../../utils/snackbar_helper.dart';

/// Login and registration page.
class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.onSignedIn,
  });

  final VoidCallback onSignedIn;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegistering = false;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (_isRegistering) {
        await SupabaseService.signUpWithEmail(email, password);
      } else {
        await SupabaseService.signInWithEmail(email, password);
      }
      if (!mounted) return;
      widget.onSignedIn();
    } catch (error) {
      if (!mounted) return;
      SnackbarHelper.showError(context, error);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                  _LoginHero(isRegistering: _isRegistering)
                      .animate()
                      .fadeIn(duration: AppDurations.page)
                      .slideY(
                        begin: -0.1,
                        end: 0,
                        duration: AppDurations.page,
                        curve: AppCurves.spring,
                      ),
                  const SizedBox(height: AppSpacing.xxl),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadii.cardRadius,
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppShadows.card,
                    ),
                    child: LoginForm(
                      formKey: _formKey,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      isRegistering: _isRegistering,
                      isLoading: _isLoading,
                      onSubmit: _submit,
                      onToggleRegister: () =>
                          setState(() => _isRegistering = !_isRegistering),
                    ),
                  )
                      .animate()
                      .fadeIn(
                        delay: const Duration(milliseconds: 80),
                        duration: AppDurations.page,
                      )
                      .slideY(
                        begin: 0.06,
                        end: 0,
                        duration: AppDurations.page,
                        curve: AppCurves.spring,
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

class _LoginHero extends StatelessWidget {
  const _LoginHero({required this.isRegistering});

  final bool isRegistering;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withAlpha(64),
                AppColors.secondary.withAlpha(32),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primary.withAlpha(60)),
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          isRegistering ? 'Create an account' : 'Welcome back',
          style: AppTextStyles.headingLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          isRegistering
              ? 'Start tracking your spend in seconds.'
              : 'Sign in to manage your expenses.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
