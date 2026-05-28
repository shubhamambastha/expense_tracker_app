import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/transaction.dart';
import '../../services/currency_settings.dart';
import '../../utils/account_management.dart';
import '../../utils/dashboard_aggregations.dart';

/// Default badge shown on account cards.
class AccountDefaultBadge extends StatelessWidget {
  const AccountDefaultBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(32),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Default',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

/// Bank account list card.
class BankAccountCard extends StatelessWidget {
  const BankAccountCard({
    super.key,
    required this.account,
    required this.transactions,
    required this.accounts,
    required this.onTap,
  });

  final Account account;
  final List<Transaction> transactions;
  final List<Account> accounts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;
    final balance =
        DashboardAggregations.accountBalance(account, transactions);
    final lastTx = AccountManagement.lastTransactionForAccount(
      account,
      transactions,
    );
    final isDefault = AccountManagement.isDefaultAccount(account.id);
    final linked = AccountManagement.linkedAccount(account, accounts);

    return _AccountCardShell(
      onTap: onTap,
      icon: AccountManagement.iconForAccount(account),
      iconTone: AppColors.primary,
      title: account.displayName,
      subtitle: account.providerLabel ?? account.name,
      trailing: Text(
        currency.formatCompact(balance),
        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w800),
      ),
      badges: [
        if (isDefault) const AccountDefaultBadge(),
      ],
      footer: [
        if (lastTx != null)
          Text(
            'Last: ${lastTx.counterpartyName}',
            style: AppTextStyles.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (linked != null)
          Text(
            'Linked: ${linked.displayName}',
            style: AppTextStyles.caption,
          ),
      ],
    );
  }
}

/// Shared card shell for account list rows.
class AccountCardShell extends StatelessWidget {
  const AccountCardShell({
    super.key,
    required this.onTap,
    required this.icon,
    required this.iconTone,
    required this.title,
    this.subtitle,
    this.trailing,
    this.badges = const [],
    this.footer = const [],
    this.progress,
    this.progressColor,
  });

  final VoidCallback onTap;
  final IconData icon;
  final Color iconTone;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> badges;
  final List<Widget> footer;
  final double? progress;
  final Color? progressColor;

  @override
  Widget build(BuildContext context) {
    return _AccountCardShell(
      onTap: onTap,
      icon: icon,
      iconTone: iconTone,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      badges: badges,
      footer: footer,
      progress: progress,
      progressColor: progressColor,
    );
  }
}

class _AccountCardShell extends StatelessWidget {
  const _AccountCardShell({
    required this.onTap,
    required this.icon,
    required this.iconTone,
    required this.title,
    this.subtitle,
    this.trailing,
    this.badges = const [],
    this.footer = const [],
    this.progress,
    this.progressColor,
  });

  final VoidCallback onTap;
  final IconData icon;
  final Color iconTone;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> badges;
  final List<Widget> footer;
  final double? progress;
  final Color? progressColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.cardRadius,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.cardRadius,
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.subtle,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconTone.withAlpha(32),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconTone, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            ...badges,
                          ],
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    trailing!,
                  ],
                ],
              ),
              if (progress != null) ...[
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: AppColors.background,
                    color: progressColor ?? AppColors.secondary,
                  ),
                ),
              ],
              if (footer.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                ...footer,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
