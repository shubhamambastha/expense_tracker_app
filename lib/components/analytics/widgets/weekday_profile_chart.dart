import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../config/design_tokens.dart';
import '../../../services/currency_settings.dart';

/// Lightweight 7-bar mini chart visualising the average spend per weekday.
///
/// Used inside the behavioural insights section to expose "where the week's
/// money goes" without ever pulling the eye away from the surrounding copy.
class WeekdayProfileChart extends StatelessWidget {
  const WeekdayProfileChart({
    super.key,
    required this.averages,
    this.height = 84,
  });

  final List<double> averages;
  final double height;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final maxValue = averages.fold<double>(0, math.max);
    final highlightIndex = _highlightIndex(averages);
    final currency = CurrencySettings.instance;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < averages.length; i++)
            Expanded(
              child: _WeekdayBar(
                label: _labels[i],
                value: averages[i],
                ratio: maxValue <= 0 ? 0 : averages[i] / maxValue,
                isWeekend: i >= 5,
                highlight: i == highlightIndex,
                amountLabel: averages[i] <= 0
                    ? '—'
                    : currency.formatCompact(averages[i]),
              ),
            ),
        ],
      ),
    );
  }

  int? _highlightIndex(List<double> averages) {
    if (averages.isEmpty) return null;
    var max = -1.0;
    var idx = -1;
    for (var i = 0; i < averages.length; i++) {
      if (averages[i] > max) {
        max = averages[i];
        idx = i;
      }
    }
    return idx;
  }
}

class _WeekdayBar extends StatelessWidget {
  const _WeekdayBar({
    required this.label,
    required this.value,
    required this.ratio,
    required this.isWeekend,
    required this.highlight,
    required this.amountLabel,
  });

  final String label;
  final double value;
  final double ratio;
  final bool isWeekend;
  final bool highlight;
  final String amountLabel;

  @override
  Widget build(BuildContext context) {
    final base = isWeekend ? AppColors.secondary : AppColors.primary;
    final color = highlight ? base : base.withAlpha(110);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: ratio),
                duration: AppDurations.reveal,
                curve: AppCurves.easeOutQuint,
                builder: (context, t, _) {
                  return FractionallySizedBox(
                    heightFactor: t.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                          bottom: Radius.circular(2),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              fontSize: 10,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              color: highlight
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            amountLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.label.copyWith(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
