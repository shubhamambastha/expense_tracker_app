import 'package:flutter/material.dart';

import '../../../config/design_tokens.dart';

/// Tiny "+12%" / "−4%" capsule next to a metric.
///
/// Direction semantics depend on the metric — for spending an increase is a
/// warning, for income/savings it's positive. The caller picks the tone via
/// [positiveOnIncrease].
class AnalyticsDeltaPill extends StatelessWidget {
  const AnalyticsDeltaPill({
    super.key,
    required this.delta,
    this.positiveOnIncrease = false,
    this.size = AnalyticsDeltaPillSize.medium,
  });

  final double? delta;

  /// True for income / savings (going up = good). False for spend / outflow.
  final bool positiveOnIncrease;

  final AnalyticsDeltaPillSize size;

  @override
  Widget build(BuildContext context) {
    final value = delta;
    if (value == null) {
      return const SizedBox.shrink();
    }
    final isIncrease = value >= 0;
    final tone = (isIncrease == positiveOnIncrease)
        ? AppColors.success
        : (value.abs() < 0.05
            ? AppColors.textSecondary
            : AppColors.warning);
    final pct = (value.abs() * 100).round();
    final arrow = isIncrease ? '↑' : '↓';
    final fontSize = size == AnalyticsDeltaPillSize.small ? 10.0 : 11.0;
    final padding = size == AnalyticsDeltaPillSize.small
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 1)
        : const EdgeInsets.symmetric(horizontal: 7, vertical: 2);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: tone.withAlpha(28),
        borderRadius: AppRadii.pillRadius,
      ),
      child: Text(
        '$arrow$pct%',
        style: AppTextStyles.label.copyWith(
          color: tone,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

enum AnalyticsDeltaPillSize { small, medium }
