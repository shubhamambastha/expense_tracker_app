import 'package:flutter/material.dart';

import '../../../config/design_tokens.dart';
import 'shimmer_box.dart';

/// Skeleton row matching [TransactionListItem] proportions.
class SkeletonTransactionRow extends StatelessWidget {
  const SkeletonTransactionRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          SkeletonBlock(
            width: 44,
            height: 44,
            borderRadius: 14,
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBlock(width: 140, height: 14),
                SizedBox(height: 6),
                SkeletonBlock(width: 96, height: 11),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SkeletonBlock(width: 64, height: 14),
              SizedBox(height: 6),
              SkeletonBlock(width: 48, height: 10),
            ],
          ),
        ],
      ),
    );
  }
}

/// Repeating transaction row skeletons for list loading.
class SkeletonTransactionList extends StatelessWidget {
  const SkeletonTransactionList({
    super.key,
    this.itemCount = 6,
    this.padding,
  });

  final int itemCount;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        children: List.generate(
          itemCount,
          (index) => const SkeletonTransactionRow(),
        ),
      ),
    );
  }
}
