import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../config/design_tokens.dart';
import '../../config/feature_flags.dart';

/// "or" divider, native Google/Apple buttons, and the guest entry point.
/// A null callback hides that option.
class SocialSignInButtons extends StatelessWidget {
  const SocialSignInButtons({
    super.key,
    required this.isLoading,
    this.onGoogle,
    this.onApple,
    this.onContinueAsGuest,
  });

  final bool isLoading;
  final VoidCallback? onGoogle;
  final VoidCallback? onApple;
  final VoidCallback? onContinueAsGuest;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text('or', style: AppTextStyles.caption),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        // Apple's HIG requires its own button style, so this one is not
        // themed with our tokens. It has no disabled state; the page ignores
        // taps while busy instead.
        if (onApple != null) ...[
          SignInWithAppleButton(
            onPressed: isLoading ? () {} : onApple!,
            style: Theme.of(context).brightness == Brightness.dark
                ? SignInWithAppleButtonStyle.white
                : SignInWithAppleButtonStyle.black,
            height: 48, // matches the themed buttons' minimumSize
            borderRadius: AppRadii.buttonRadius,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (onGoogle != null)
          OutlinedButton.icon(
            onPressed: isLoading ? null : onGoogle,
            icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
            label: const Text('Continue with Google'),
          ),
        if (FeatureFlags.guestModeEnabled && onContinueAsGuest != null) ...[
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: isLoading ? null : onContinueAsGuest,
            child: const Text('Continue as guest'),
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
