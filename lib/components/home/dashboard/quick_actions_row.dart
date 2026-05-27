import 'package:flutter/material.dart';

import '../../../config/design_tokens.dart';
import 'dashboard_intents.dart';

/// Four thumb-sized shortcuts: Add Expense, Add Income, Transfer, Add EMI.
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key, required this.onAction});

  final void Function(QuickAction action) onAction;

  static const List<_QuickActionSpec> _specs = [
    _QuickActionSpec(
      action: QuickAction.addExpense,
      label: 'Expense',
      icon: Icons.south_west_rounded,
      tint: AppColors.danger,
    ),
    _QuickActionSpec(
      action: QuickAction.addIncome,
      label: 'Income',
      icon: Icons.north_east_rounded,
      tint: AppColors.success,
    ),
    _QuickActionSpec(
      action: QuickAction.transfer,
      label: 'Transfer',
      icon: Icons.swap_horiz_rounded,
      tint: AppColors.secondary,
    ),
    _QuickActionSpec(
      action: QuickAction.addEmi,
      label: 'EMI',
      icon: Icons.event_repeat_rounded,
      tint: AppColors.warning,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _specs.length; i++) ...[
          Expanded(
            child: _QuickActionChip(
              spec: _specs[i],
              onTap: () => onAction(_specs[i].action),
            ),
          ),
          if (i != _specs.length - 1) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _QuickActionSpec {
  const _QuickActionSpec({
    required this.action,
    required this.label,
    required this.icon,
    required this.tint,
  });

  final QuickAction action;
  final String label;
  final IconData icon;
  final Color tint;
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({required this.spec, required this.onTap});

  final _QuickActionSpec spec;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.buttonRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.buttonRadius,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: spec.tint.withAlpha(36),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(spec.icon, color: spec.tint, size: 20),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                spec.label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
