import 'package:flutter/material.dart';

import '../../../config/design_tokens.dart';
import '../../../services/currency_settings.dart';
import 'dashboard_section_header.dart';

/// "Spending Room" — today's discretionary allowance, accrued through the
/// month from income minus recurring commitments, minus what's actually
/// been spent so far. Deliberately not called "Today" to avoid reading like
/// [DashboardAggregations.todaySpend] (today's transactions only) — this
/// number is cumulative within the month, not a single day's total.
class SpendingRoomCard extends StatelessWidget {
  const SpendingRoomCard({
    super.key,
    required this.amount,
    required this.hasIncomeThisMonth,
  });

  final double amount;

  /// False when no income has been logged for the current month yet — the
  /// formula would otherwise show a misleadingly deep negative number before
  /// the user's salary/income lands.
  final bool hasIncomeThisMonth;

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionHeader(
          title: 'Spending Room',
          subtitle: "Based on this month's income minus expenses",
        ),
        const SizedBox(height: AppSpacing.md),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.cardRadius,
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: hasIncomeThisMonth
                ? _AmountRow(amount: amount, currency: currency)
                : const _NoIncomeYet(),
          ),
        ),
      ],
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.amount, required this.currency});

  final double amount;
  final CurrencySettings currency;

  @override
  Widget build(BuildContext context) {
    final isNegative = amount < 0;
    final color = isNegative ? AppColors.danger : AppColors.success;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withAlpha(24),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(
            isNegative
                ? Icons.trending_down_rounded
                : Icons.account_balance_wallet_rounded,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isNegative ? 'Over budget this month' : 'Safe to spend',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                currency.formatCompact(amount),
                style: AppTextStyles.headingSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NoIncomeYet extends StatelessWidget {
  const _NoIncomeYet();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(24),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.wallet_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            "Log this month's income to see today's spending room.",
            style: AppTextStyles.bodySmall,
          ),
        ),
      ],
    );
  }
}
