import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../services/currency_settings.dart';

/// Glanceable summary of total available, credit used, and cash.
class AccountsSummaryCard extends StatelessWidget {
  const AccountsSummaryCard({
    super.key,
    required this.totalAvailable,
    required this.totalCreditUsed,
    required this.cashAvailable,
  });

  final double totalAvailable;
  final double totalCreditUsed;
  final double cashAvailable;

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.surfaceSecondary],
        ),
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: _MetricTile(
              label: 'Available',
              value: currency.formatCompact(totalAvailable),
              icon: Icons.account_balance_rounded,
              tone: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _MetricTile(
              label: 'Credit used',
              value: currency.formatCompact(totalCreditUsed),
              icon: Icons.credit_card_rounded,
              tone: AppColors.warning,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _MetricTile(
              label: 'Cash',
              value: currency.formatCompact(cashAvailable),
              icon: Icons.payments_rounded,
              tone: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: tone.withAlpha(24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: tone),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
