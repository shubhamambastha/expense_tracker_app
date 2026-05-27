import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart' as intl;

import '../../config/design_tokens.dart';
import '../../utils/analytics_aggregations.dart';

/// Top of the Analytics screen — title, the resolved period chip, and a
/// "compare" placeholder hook so the layout already reserves space for an
/// upcoming feature.
class AnalyticsHeader extends StatelessWidget {
  const AnalyticsHeader({
    super.key,
    required this.range,
    required this.resolvedRange,
    this.onCompareTap,
  });

  final AnalyticsRange range;
  final ResolvedRange resolvedRange;
  final VoidCallback? onCompareTap;

  String _formatPeriod() {
    final start = resolvedRange.start;
    final end = resolvedRange.end;
    final sameYear = start.year == end.year;
    final sameMonth = sameYear && start.month == end.month;
    if (sameMonth) {
      return '${intl.DateFormat('MMM yyyy').format(start)}'
          ' · ${range.label}';
    }
    final startFmt = intl.DateFormat(sameYear ? 'd MMM' : 'd MMM yy');
    final endFmt = intl.DateFormat('d MMM yy');
    return '${startFmt.format(start)} – ${endFmt.format(end)} · ${range.label}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analytics',
                style: AppTextStyles.headingLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _formatPeriod(),
                style: AppTextStyles.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        _CompareButton(onTap: onCompareTap),
      ],
    )
        .animate()
        .fadeIn(duration: AppDurations.reveal)
        .slideY(
          begin: -0.08,
          end: 0,
          duration: AppDurations.reveal,
          curve: AppCurves.spring,
        );
  }
}

class _CompareButton extends StatelessWidget {
  const _CompareButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.pillRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.pillRadius,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.compare_arrows_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Compare',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
