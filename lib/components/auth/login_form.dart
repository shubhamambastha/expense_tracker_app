import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';

typedef SubmitCallback = Future<void> Function();

/// Auth0 Universal Login entry point.
class LoginForm extends StatelessWidget {
  const LoginForm({
    super.key,
    required this.isLoading,
    required this.onSignIn,
  });

  final bool isLoading;
  final SubmitCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sign in or create an account securely with Auth0.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isLoading ? null : onSignIn,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF003328),
                    ),
                  )
                : const Text('Continue with Auth0'),
          ),
        ),
      ],
    );
  }
}
