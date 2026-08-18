import 'package:flutter/material.dart';

import '../../../../config/design_tokens.dart';
import '../../../../utils/transaction_date_format.dart';
import '../transaction_detail_view_data.dart';
import '../widgets/detail_info_row.dart';
import '../widgets/detail_section_card.dart';

class ActivityMetadataSection extends StatefulWidget {
  const ActivityMetadataSection({super.key, required this.data});

  final TransactionDetailViewData data;

  @override
  State<ActivityMetadataSection> createState() =>
      _ActivityMetadataSectionState();
}

class _ActivityMetadataSectionState extends State<ActivityMetadataSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tx = widget.data.tx;
    final hasCreated = tx.insertedAt != null;
    final hasCurrency = widget.data.showCurrencyMetadata;

    if (!hasCreated && !hasCurrency) {
      return const SizedBox.shrink();
    }

    return DetailSectionCard(
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
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Activity',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
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
                        Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: AppSpacing.sm),
                        if (hasCreated)
                          DetailInfoRow(
                            label: 'Created',
                            value: formatTransactionDetailDateTime(
                              tx.insertedAt!,
                            ),
                          ),
                        if (hasCurrency)
                          DetailInfoRow(
                            label: 'Currency',
                            value: tx.currencyCode,
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
