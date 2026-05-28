import 'package:flutter/material.dart';

import '../../../config/design_tokens.dart';
import 'shimmer_box.dart';

/// Generic skeleton card preserving dashboard/analytics card proportions.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    super.key,
    this.height = 160,
    this.showHeader = true,
    this.showFooter = false,
    this.child,
  });

  final double height;
  final bool showHeader;
  final bool showFooter;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: child == null ? height : null,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: child ??
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showHeader) ...[
                const SkeletonBlock(width: 120, height: 12),
                const SizedBox(height: AppSpacing.md),
                const SkeletonBlock(width: 180, height: 28, borderRadius: 10),
                const SizedBox(height: AppSpacing.lg),
              ],
              const Expanded(
                child: SkeletonBlock(
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: 12,
                ),
              ),
              if (showFooter) ...[
                const SizedBox(height: AppSpacing.md),
                const SkeletonBlock(width: 140, height: 10),
              ],
            ],
          ),
    );
  }
}

/// Hero-sized overview skeleton for dashboard loading.
class SkeletonHeroCard extends StatelessWidget {
  const SkeletonHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      height: 188,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonBlock(width: 88, height: 12),
              const Spacer(),
              SkeletonBlock(
                width: 64,
                height: 24,
                borderRadius: AppRadii.pill,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const SkeletonBlock(width: 160, height: 36, borderRadius: 10),
          const SizedBox(height: AppSpacing.sm),
          const SkeletonBlock(width: 200, height: 14),
          const SizedBox(height: AppSpacing.xl),
          const SkeletonBlock(
            width: double.infinity,
            height: 8,
            borderRadius: AppRadii.pill,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Expanded(
                child: SkeletonBlock(height: 52, borderRadius: 14),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: SkeletonBlock(height: 52, borderRadius: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact metric tile skeleton for analytics grids.
class SkeletonMetricTile extends StatelessWidget {
  const SkeletonMetricTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBlock(width: 72, height: 10),
          SizedBox(height: AppSpacing.sm),
          SkeletonBlock(width: 96, height: 22, borderRadius: 8),
          SizedBox(height: AppSpacing.xs),
          SkeletonBlock(width: 48, height: 10),
        ],
      ),
    );
  }
}

/// Chart area placeholder for analytics loading.
class SkeletonChartPlaceholder extends StatelessWidget {
  const SkeletonChartPlaceholder({super.key, this.height = 180});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      height: height,
      showHeader: true,
      showFooter: true,
    );
  }
}
