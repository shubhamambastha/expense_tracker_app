import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';

/// One-time first-run tip about long-press retroactive tagging — the one
/// subscription-picker capability with no visual affordance of its own
/// (picking "Subscription" as the category already auto-opens the brand
/// picker, so that half needs no separate hint). Dismissed permanently
/// once tapped away.
class SubscriptionHintBanner extends StatelessWidget {
  const SubscriptionHintBanner({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: AppRadii.chipRadius,
          border: Border.all(color: AppColors.primary.withAlpha(70)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.touch_app_rounded, color: AppColors.primary, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Tip: long-press any transaction in the list later to tag '
                'it as a subscription with its own brand icon.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Semantics(
              label: 'Dismiss tip',
              button: true,
              child: SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: onDismiss,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
