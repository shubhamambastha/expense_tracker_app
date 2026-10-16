import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/design_tokens.dart';
import '../common/compact_header.dart';
import '../common/states/states.dart';

/// Shared layout for the sign-in screens: heading, subtext, then [body],
/// with a back button whenever the page was pushed.
class AuthPageScaffold extends StatelessWidget {
  const AuthPageScaffold({
    super.key,
    required this.heading,
    required this.subtext,
    required this.body,
  });

  final String heading;
  final String subtext;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          CompactHeader(
            child: canPop
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  )
                : null,
          ),
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
                        heading,
                        style: AppTextStyles.displaySmall,
                        textAlign: TextAlign.center,
                      )
                      .animate()
                      .fadeIn(duration: AppDurations.page)
                      .slideY(begin: 0.08, end: 0),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    subtext,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(
                    duration: AppDurations.page,
                    delay: AppDurations.stagger * 2,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  body.animate().fadeIn(
                    duration: AppDurations.page,
                    delay: AppDurations.stagger * 3,
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

/// Primary button that swaps its label for an inline spinner while busy.
class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      // Keep the primary fill while busy; the default disabled grey hides the spinner in dark mode.
      style: isLoading
          ? FilledButton.styleFrom(disabledBackgroundColor: AppColors.primary)
          : null,
      child: isLoading
          ? const AppLoadingIndicator(
              style: AppLoadingStyle.inline,
              color: AppColors.onPrimary,
            )
          : Text(label),
    );
  }
}
