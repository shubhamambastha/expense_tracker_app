import 'package:flutter/material.dart';

import '../../../../config/design_tokens.dart';
import '../../../../models/transaction_draft.dart';
import '../../../../utils/transaction_date_format.dart';
import '../../../../utils/transaction_subtype_helpers.dart';
import '../transaction_detail_view_data.dart';
import '../widgets/detail_info_row.dart';
import '../widgets/detail_section_card.dart';

class RecurringDetailsSection extends StatefulWidget {
  const RecurringDetailsSection({super.key, required this.data});

  final TransactionDetailViewData data;

  @override
  State<RecurringDetailsSection> createState() =>
      _RecurringDetailsSectionState();
}

class _RecurringDetailsSectionState extends State<RecurringDetailsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tx = widget.data.tx;
    if (!tx.isRecurring) return const SizedBox.shrink();

    final frequency = tx.recurrenceFrequency ?? RecurrenceFrequency.monthly;
    final isEmi = TransactionSubtypeHelpers.isEmiCategory(tx.category);
    final isSubscription =
        TransactionSubtypeHelpers.isSubscriptionCategory(tx.category);
    final nextDate = widget.data.nextPaymentDate;
    final remainingMonths = widget.data.emiRemainingMonths;

    return DetailSectionCard(
      accentColor: AppColors.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: AppRadii.cardRadius,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(
                    Icons.autorenew_rounded,
                    size: 20,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${frequency.label} recurring',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (nextDate != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Next: ${formatTransactionDetailDate(nextDate)}',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isEmi || isSubscription) ...[
                    _SubtypeBadge(
                      label: isEmi ? 'EMI' : 'Subscription',
                      color: isEmi ? AppColors.warning : AppColors.secondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: AppDurations.page,
            curve: AppCurves.emphasized,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Column(
                      children: [
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: AppSpacing.sm),
                        if (tx.reminderTiming != null)
                          DetailInfoRow(
                            label: 'Reminder',
                            value: tx.reminderTiming!.label,
                          ),
                        if (tx.recurrenceStartDate != null)
                          DetailInfoRow(
                            label: 'Start date',
                            value: formatTransactionDetailDate(
                              tx.recurrenceStartDate!,
                            ),
                          ),
                        DetailInfoRow(
                          label: 'End date',
                          value: tx.recurrenceEndDate != null
                              ? formatTransactionDetailDate(
                                  tx.recurrenceEndDate!,
                                )
                              : 'No end date',
                        ),
                        if (nextDate != null)
                          DetailInfoRow(
                            label: isSubscription
                                ? 'Renewal date'
                                : 'Next payment',
                            value: formatTransactionDetailDate(nextDate),
                          ),
                        if (remainingMonths != null)
                          DetailInfoRow(
                            label: 'EMI remaining',
                            value:
                                '$remainingMonths month${remainingMonths == 1 ? '' : 's'}',
                          ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _SubtypeBadge extends StatelessWidget {
  const _SubtypeBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: AppRadii.chipRadius,
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
