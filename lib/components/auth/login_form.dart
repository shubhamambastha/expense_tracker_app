import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../config/feature_flags.dart';

typedef SubmitCallback = Future<void> Function();

/// Auth0 Universal Login entry point, with an optional guest path.
class LoginForm extends StatelessWidget {
  const LoginForm({
    super.key,
    required this.isLoading,
    required this.onSignIn,
    this.onContinueAsGuest,
  });

  final bool isLoading;
  final SubmitCallback onSignIn;

  /// Null hides the guest entry point entirely (also gated on
  /// [FeatureFlags.guestModeEnabled] by the caller).
  final SubmitCallback? onContinueAsGuest;

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
        if (FeatureFlags.guestModeEnabled && onContinueAsGuest != null) ...[
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: isLoading ? null : onContinueAsGuest,
              child: const Text('Continue as guest'),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your data stays on this device until you sign in.',
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
