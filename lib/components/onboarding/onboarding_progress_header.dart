import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';

/// Persistent "step X of 5" progress bar shown above every wizard step,
/// including the two steps that push a full-screen [AddTransactionPage] —
/// this is what stops the wizard's flow from reading as "leaving setup"
/// when those screens appear (see docs/designs/post-login-onboarding.md,
/// T10). A thin linear bar, not a dot-stepper — dots don't communicate
/// "3 of 5" as precisely for a 5-step flow.
class OnboardingProgressHeader extends StatelessWidget {
  const OnboardingProgressHeader({
    super.key,
    required this.stepIndex,
    required this.stepCount,
  });

  final int stepIndex;
  final int stepCount;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: ClipRRect(
          borderRadius: AppRadii.chipRadius,
          child: LinearProgressIndicator(
            value: (stepIndex + 1) / stepCount,
            minHeight: 4,
            backgroundColor: AppColors.surfaceSecondary,
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ),
    );
  }
}
