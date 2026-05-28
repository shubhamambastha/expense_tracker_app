import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/transaction.dart';
import '../../services/currency_settings.dart';
import '../../utils/account_management.dart';
import 'bank_account_card.dart';

enum CreditCardQuickAction { edit, payBill, addEmi }

/// Credit card list card with utilization and quick actions.
class CreditCardCard extends StatelessWidget {
  const CreditCardCard({
    super.key,
    required this.account,
    required this.transactions,
    required this.accounts,
    required this.onTap,
    this.onQuickAction,
  });

  final Account account;
  final List<Transaction> transactions;
  final List<Account> accounts;
  final VoidCallback onTap;
  final void Function(CreditCardQuickAction action)? onQuickAction;

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;
    final util = AccountManagement.creditUtilization(account, transactions);
    final billing = AccountManagement.billingLabels(account);
    final toneColor = AccountManagement.toneColor(util.tone);
    final linked = AccountManagement.linkedAccount(account, accounts);
    final dueSoon = AccountManagement.dueSoon(account);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AccountCardShell(
          onTap: onTap,
          icon: Icons.credit_card_rounded,
          iconTone: toneColor,
          title: account.displayName,
          subtitle: account.providerLabel ?? 'Credit Card',
          trailing: util.limit != null && util.limit! > 0
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${currency.formatCompact(util.used)} / ${currency.formatCompact(util.limit!)}',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${currency.formatCompact(util.available)} available',
                      style: AppTextStyles.caption,
                    ),
                  ],
                )
              : Text(
                  currency.formatCompact(util.used),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
          badges: [
            if (dueSoon)
              _WarningChip(
                label: 'Due soon',
                tone: AppColors.warning,
              ),
            if (util.tone == AccountWarningTone.danger)
              _WarningChip(
                label: 'High usage',
                tone: AppColors.danger,
              ),
          ],
          progress: util.limit != null && util.limit! > 0 ? util.ratio : null,
          progressColor: toneColor,
          footer: [
            if (billing.dueLabel != null)
              Text(
                billing.dueLabel!,
                style: AppTextStyles.caption.copyWith(
                  color: dueSoon ? AppColors.warning : null,
                  fontWeight: dueSoon ? FontWeight.w700 : null,
                ),
              ),
            if (linked != null)
              Text(
                'Pays from ${linked.displayName}',
                style: AppTextStyles.caption,
              ),
          ],
        ),
        if (onQuickAction != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              _QuickActionChip(
                label: 'Edit',
                icon: Icons.edit_rounded,
                onTap: () => onQuickAction!(CreditCardQuickAction.edit),
              ),
              const SizedBox(width: AppSpacing.xs),
              _QuickActionChip(
                label: 'Pay bill',
                icon: Icons.payment_rounded,
                onTap: () => onQuickAction!(CreditCardQuickAction.payBill),
              ),
              const SizedBox(width: AppSpacing.xs),
              _QuickActionChip(
                label: 'Add EMI',
                icon: Icons.receipt_long_rounded,
                onTap: () => onQuickAction!(CreditCardQuickAction.addEmi),
              ),
            ],
          ),
        ],
      ],
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
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tone.withAlpha(32),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: tone,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xs,
              horizontal: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
