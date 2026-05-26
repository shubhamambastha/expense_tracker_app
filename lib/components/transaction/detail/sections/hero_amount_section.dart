import 'package:flutter/material.dart';

import '../../../../config/design_tokens.dart';
import '../../../../models/transaction_filters.dart';
import '../../../../utils/transaction_date_format.dart';
import '../transaction_detail_view_data.dart';

class HeroAmountSection extends StatelessWidget {
  const HeroAmountSection({super.key, required this.data});

  final TransactionDetailViewData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: data.categoryColor.withAlpha(32),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            data.categoryIcon,
            color: data.categoryColor,
            size: 28,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          data.amountLabel,
          style: AppTextStyles.displaySmall.copyWith(
            fontWeight: FontWeight.w800,
            color: data.amountColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          data.displayType.label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: data.categoryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          formatTransactionDetailDateTime(data.tx.date),
          style: AppTextStyles.caption,
        ),
        if (data.contextLabel.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            data.contextLabel,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
