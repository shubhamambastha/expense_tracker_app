import 'package:flutter/material.dart';

import '../../../config/design_tokens.dart';
import 'analytics_delta_pill.dart';

/// A compact "label + amount + delta" tile used in the Spending Overview
/// grid. Designed to live in a 2-up row.
class AnalyticsMetricCard extends StatelessWidget {
  const AnalyticsMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.tint,
    this.delta,
    this.deltaPositiveOnIncrease = false,
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? tint;
  final double? delta;
  final bool deltaPositiveOnIncrease;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final accent = tint ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
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
              if (icon != null) ...[
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: accent.withAlpha(32),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: accent, size: 14),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          if (subtitle != null || delta != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                if (delta != null)
                  AnalyticsDeltaPill(
                    delta: delta,
                    positiveOnIncrease: deltaPositiveOnIncrease,
                    size: AnalyticsDeltaPillSize.small,
                  ),
                if (delta != null && subtitle != null)
                  const SizedBox(width: AppSpacing.xs),
                if (subtitle != null)
                  Expanded(
                    child: Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(fontSize: 11),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
