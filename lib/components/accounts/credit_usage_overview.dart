import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/transaction.dart';
import '../../services/currency_settings.dart';
import '../../utils/account_management.dart';
import '../transaction/detail/widgets/detail_section_card.dart';

/// Credit usage overview for credit card detail screen.
class CreditUsageOverview extends StatelessWidget {
  const CreditUsageOverview({
    super.key,
    required this.account,
    required this.transactions,
  });

  final Account account;
  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;
    final util = AccountManagement.creditUtilization(account, transactions);
    final toneColor = AccountManagement.toneColor(util.tone);
    final dueSoon = AccountManagement.dueSoon(account);
    final percent = (util.ratio * 100).round();

    return DetailSectionCard(
      title: 'Credit usage',
      accentColor: toneColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currency.format(util.used),
            style: AppTextStyles.headingMedium,
          ),
          Text('used of ${currency.format(util.limit ?? 0)} limit',
              style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: util.limit != null && util.limit! > 0 ? util.ratio : null,
              minHeight: 6,
              backgroundColor: AppColors.background,
              color: toneColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${currency.format(util.available)} available',
                style: AppTextStyles.bodyMedium,
              ),
              Text(
                '$percent% utilized',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: toneColor,
                ),
              ),
            ],
          ),
          if (dueSoon || util.tone != AccountWarningTone.none) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                if (dueSoon)
                  const _WarningChip(
                    label: 'Due soon',
                    tone: AppColors.warning,
                  ),
                if (util.tone == AccountWarningTone.danger)
                  const _WarningChip(
                    label: 'High utilization',
                    tone: AppColors.danger,
                  ),
                if (util.tone == AccountWarningTone.warning)
                  const _WarningChip(
                    label: 'Nearing limit',
                    tone: AppColors.warning,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _WarningChip extends StatelessWidget {
  const _WarningChip({required this.label, required this.tone});

  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tone.withAlpha(32),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: tone,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
