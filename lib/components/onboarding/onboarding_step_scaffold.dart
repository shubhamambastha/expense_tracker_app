import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';

/// Shared layout for the 3 inline wizard steps (name/currency/budget):
/// heading, subtext, body, then a Skip / Next row. Buttons: Skip as a text
/// button (no fill), Next as a filled primary button — matches the app's
/// existing button vocabulary, no new pattern introduced.
class OnboardingStepScaffold extends StatelessWidget {
  const OnboardingStepScaffold({
    super.key,
    required this.heading,
    required this.subtext,
    required this.body,
    required this.onSkip,
    required this.onNext,
    this.onBack,
    this.nextLabel = 'Next',
  });

  final String heading;
  final String subtext;
  final Widget body;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  /// Top-left back button. Null on the first step (nothing to go back to —
  /// hardware back is blocked for the whole wizard, this is the only way
  /// to move backward).
  final VoidCallback? onBack;

  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Everything above the button row lives in ONE flex child
          // (Expanded, the only one in this Column) so it — not a second
          // Spacer — absorbs 100% of the leftover space. Two flex children
          // of equal weight (a Flexible body + a Spacer) split that space
          // 50/50 instead, which is what previously left the button row
          // stranded mid-screen on short steps instead of pinned to the
          // bottom.
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (onBack != null) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Tooltip(
                        message: 'Back',
                        child: InkWell(
                          onTap: onBack,
                          borderRadius: AppRadii.buttonRadius,
                          child: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: AppRadii.buttonRadius,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: AppColors.textPrimary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  Text(heading, style: AppTextStyles.headingLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtext, style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  )),
                  const SizedBox(height: AppSpacing.xxl),
                  body,
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
                child: const Text('Skip'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  shape: AppRadii.buttonBorder,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                    vertical: AppSpacing.md,
                  ),
                ),
                child: Text(nextLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
