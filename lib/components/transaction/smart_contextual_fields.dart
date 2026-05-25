import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';

/// Contextual recurring-only fields shown when the chosen category is EMI
/// or Subscription. Intentionally lightweight — these are *hints* that the
/// screen architecture supports progressive disclosure; the real fields will
/// land alongside the EMI/Subscription persistence model.
class SmartContextualFields extends StatelessWidget {
  const SmartContextualFields({
    super.key,
    required this.categoryName,
  });

  final String categoryName;

  bool get _isEmi => categoryName.toLowerCase().contains('emi');
  bool get _isSubscription =>
      categoryName.toLowerCase().contains('subscription');

  @override
  Widget build(BuildContext context) {
    final accent =
        _isSubscription ? AppColors.secondary : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: accent.withAlpha(16),
        borderRadius: AppRadii.chipRadius,
        border: Border.all(color: accent.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                _isEmi ? Icons.account_balance_rounded : Icons.subscriptions_rounded,
                size: 16,
                color: accent,
              ),
              const SizedBox(width: 6),
              Text(
                _isEmi ? 'EMI details' : 'Subscription details',
                style: AppTextStyles.label.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_isEmi) ...const [
            _ContextRow(
              icon: Icons.credit_card_rounded,
              label: 'Linked account / card',
              value: 'Tap to choose',
            ),
            _ContextRow(
              icon: Icons.event_rounded,
              label: 'Next due date',
              value: 'Auto from start',
            ),
            _ContextRow(
              icon: Icons.repeat_rounded,
              label: 'Remaining months',
              value: 'Optional',
            ),
          ] else if (_isSubscription) ...const [
            _ContextRow(
              icon: Icons.credit_card_rounded,
              label: 'Linked account / card',
              value: 'Tap to choose',
            ),
            _ContextRow(
              icon: Icons.event_rounded,
              label: 'Next due date',
              value: 'Auto from start',
            ),
            _ContextRow(
              icon: Icons.calendar_view_month_rounded,
              label: 'Billing cycle',
              value: 'Matches frequency',
            ),
          ],
        ],
      ),
    );
  }
}

class _ContextRow extends StatelessWidget {
  const _ContextRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(value, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
