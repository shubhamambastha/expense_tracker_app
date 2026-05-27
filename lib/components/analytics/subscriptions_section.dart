import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/transaction.dart';
import '../../models/transaction_draft.dart';
import '../../services/category_catalog.dart';
import '../../services/currency_settings.dart';
import '../../utils/analytics_aggregations.dart';
import '../home/dashboard/dashboard_section_header.dart';
import 'widgets/analytics_section_card.dart';

/// "Subscription & Recurring" — surface recurring monthly outflows (EMI,
/// subscriptions, rent, etc.) and the total burden in a normalised
/// per-month figure.
class SubscriptionsSection extends StatelessWidget {
  const SubscriptionsSection({
    super.key,
    required this.summary,
    required this.accounts,
    required this.onTapItem,
  });

  final RecurringSummary summary;
  final List<Account> accounts;
  final void Function(Transaction transaction) onTapItem;

  Account? _accountFor(int? id) {
    if (id == null) return null;
    for (final a in accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionHeader(
          title: 'Subscriptions & Recurring',
          subtitle: summary.isEmpty
              ? 'Mark a transaction as recurring to track its monthly burden.'
              : 'Normalised to per-month so you can compare.',
        ),
        const SizedBox(height: AppSpacing.md),
        if (summary.isEmpty)
          AnalyticsSectionCard(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withAlpha(24),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.subscriptions_rounded,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Expanded(
                  child: Text(
                    'No recurring expenses yet. Add bills, EMIs, or subscriptions to surface them here.',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            ),
          )
        else
          AnalyticsSectionCard(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryStrip(summary: summary),
                const SizedBox(height: AppSpacing.md),
                _InsightLine(summary: summary),
                const SizedBox(height: AppSpacing.md),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.border,
                ),
                const SizedBox(height: AppSpacing.sm),
                for (var i = 0;
                    i < summary.commitments.length;
                    i++) ...[
                  _RecurringRow(
                    commitment: summary.commitments[i],
                    account: _accountFor(
                      summary.commitments[i].transaction.accountId,
                    ),
                    onTap: () =>
                        onTapItem(summary.commitments[i].transaction),
                  ),
                  if (i != summary.commitments.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.border,
                      indent: 42,
                    ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.summary});

  final RecurringSummary summary;

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Monthly total',
            value: currency.formatCompact(summary.totalMonthly),
            tone: AppColors.primary,
            icon: Icons.event_repeat_rounded,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SummaryTile(
            label: 'Subscriptions',
            value: currency.formatCompact(summary.subscriptionsTotal),
            tone: AppColors.secondary,
            icon: Icons.subscriptions_rounded,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SummaryTile(
            label: 'EMI',
            value: currency.formatCompact(summary.emiTotal),
            tone: AppColors.warning,
            icon: Icons.receipt_long_rounded,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.tone,
    required this.icon,
  });

  final String label;
  final String value;
  final Color tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: tone.withAlpha(32),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 12, color: tone),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightLine extends StatelessWidget {
  const _InsightLine({required this.summary});

  final RecurringSummary summary;

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;
    final total = summary.totalMonthly;
    final subscriptions = summary.subscriptionsTotal;
    final emi = summary.emiTotal;
    final count = summary.commitments.length;
    String message;
    if (subscriptions > 0 && subscriptions / total > 0.5) {
      message = 'Subscriptions make up the bulk of your recurring outflow at '
          '${currency.formatCompact(subscriptions)} per month.';
    } else if (emi > 0 && emi / total > 0.5) {
      message = 'EMI is the heaviest recurring slice at '
          '${currency.formatCompact(emi)} per month.';
    } else if (count >= 5) {
      message = '$count recurring commitments add up to '
          '${currency.formatCompact(total)} every month.';
    } else {
      message = 'About ${currency.formatCompact(total)} leaves your accounts '
          'on autopilot each month.';
    }
    return Text(
      message,
      style: AppTextStyles.bodySmall.copyWith(
        color: AppColors.textPrimary,
        height: 1.4,
      ),
    );
  }
}

class _RecurringRow extends StatelessWidget {
  const _RecurringRow({
    required this.commitment,
    required this.account,
    required this.onTap,
  });

  final RecurringCommitment commitment;
  final Account? account;
  final VoidCallback onTap;

  Color get _accent {
    if (commitment.isSubscription) return AppColors.secondary;
    if (commitment.isEmi) return AppColors.warning;
    return AppColors.primary;
  }

  IconData get _icon {
    if (commitment.isSubscription) return Icons.subscriptions_rounded;
    if (commitment.isEmi) return Icons.receipt_long_rounded;
    final cat = commitment.transaction.category;
    if (cat != null) return CategoryCatalog.instance.iconForName(cat);
    return Icons.autorenew_rounded;
  }

  String get _cycleLabel {
    final freq = commitment.transaction.recurrenceFrequency;
    return (freq ?? RecurrenceFrequency.monthly).label;
  }

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _accent.withAlpha(32),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon, color: _accent, size: 16),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      commitment.transaction.counterpartyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: _accent.withAlpha(22),
                            borderRadius: AppRadii.pillRadius,
                          ),
                          child: Text(
                            _cycleLabel,
                            style: AppTextStyles.label.copyWith(
                              color: _accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            account?.name ??
                                commitment.transaction.category ??
                                'Auto',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currency.formatCompact(commitment.monthlyEquivalent),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'per month',
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
