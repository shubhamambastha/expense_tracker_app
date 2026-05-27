import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../utils/analytics_aggregations.dart';

/// Horizontally scrollable range chips: This Week, This Month, Last Month,
/// 3M, 6M, This Year, Custom.
///
/// Selection visuals follow the dashboard's pill-button convention (accent
/// tinted background, primary text, soft spring on selection change).
class TimeRangeSelector extends StatelessWidget {
  const TimeRangeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.onPickCustom,
  });

  final AnalyticsRange selected;
  final ValueChanged<AnalyticsRange> onChanged;
  final VoidCallback onPickCustom;

  static const List<AnalyticsRange> _order = [
    AnalyticsRange.thisWeek,
    AnalyticsRange.thisMonth,
    AnalyticsRange.lastMonth,
    AnalyticsRange.threeMonths,
    AnalyticsRange.sixMonths,
    AnalyticsRange.thisYear,
    AnalyticsRange.custom,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _order.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final range = _order[index];
          return _RangeChip(
            label: range.label,
            isSelected: selected == range,
            onTap: () {
              if (range == AnalyticsRange.custom) {
                onPickCustom();
              } else {
                onChanged(range);
              }
            },
          );
        },
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = isSelected ? AppColors.primary : AppColors.textSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.pillRadius,
        child: AnimatedContainer(
          duration: AppDurations.micro,
          curve: AppCurves.spring,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withAlpha(32)
                : AppColors.surface,
            borderRadius: AppRadii.pillRadius,
            border: Border.all(
              color: isSelected
                  ? AppColors.primary.withAlpha(80)
                  : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: fg,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
