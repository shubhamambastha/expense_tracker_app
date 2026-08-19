import 'package:flutter/material.dart';

import '../../../config/design_tokens.dart';

/// Thumb-sized shortcuts: add expense, jump to recurring, jump to analytics.
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({
    super.key,
    required this.onAddExpense,
    required this.onRecurring,
    required this.onAnalytics,
  });

  final VoidCallback onAddExpense;
  final VoidCallback onRecurring;
  final VoidCallback onAnalytics;

  @override
  Widget build(BuildContext context) {
    final specs = [
      _QuickActionSpec(
        label: 'Add Expense',
        icon: Icons.add_rounded,
        tint: AppColors.danger,
        onTap: onAddExpense,
      ),
      _QuickActionSpec(
        label: 'Recurring',
        icon: Icons.repeat_rounded,
        tint: AppColors.warning,
        onTap: onRecurring,
      ),
      _QuickActionSpec(
        label: 'Analytics',
        icon: Icons.insights_rounded,
        tint: AppColors.secondary,
        onTap: onAnalytics,
      ),
    ];
    return Row(
      children: [
        for (var i = 0; i < specs.length; i++) ...[
          Expanded(child: _QuickActionChip(spec: specs[i])),
          if (i != specs.length - 1) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _QuickActionSpec {
  const _QuickActionSpec({
    required this.label,
    required this.icon,
    required this.tint,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({required this.spec});

  final _QuickActionSpec spec;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: spec.onTap,
        borderRadius: AppRadii.buttonRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.buttonRadius,
          ),
          child: Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: spec.tint.withAlpha(36),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(spec.icon, color: spec.tint, size: 18),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                spec.label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
