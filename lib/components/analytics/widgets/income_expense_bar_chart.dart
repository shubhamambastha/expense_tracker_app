import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../config/design_tokens.dart';
import '../../../services/currency_settings.dart';
import '../../../utils/analytics_aggregations.dart';

/// Paired vertical bars (income / expense) with a tappable selection state.
///
/// Stays lightweight — uses [CustomPaint] so we don't pull in a charting
/// dependency just for a comparison view.
class IncomeExpenseBarChart extends StatefulWidget {
  const IncomeExpenseBarChart({
    super.key,
    required this.buckets,
    this.height = 168,
  });

  final List<PeriodBucket> buckets;
  final double height;

  @override
  State<IncomeExpenseBarChart> createState() => _IncomeExpenseBarChartState();
}

class _IncomeExpenseBarChartState extends State<IncomeExpenseBarChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final buckets = widget.buckets;
    if (buckets.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            'No income or expenses in this range yet.',
            style: AppTextStyles.bodySmall,
          ),
        ),
      );
    }

    final maxValue = buckets.fold<double>(
      0,
      (m, b) => math.max(m, math.max(b.income, b.expense)),
    );
    final selected = _selectedIndex;
    final selectedBucket = (selected != null && selected < buckets.length)
        ? buckets[selected]
        : null;
    final currency = CurrencySettings.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 24,
          child: selectedBucket == null
              ? Row(
                  children: const [
                    _LegendDot(color: AppColors.success, label: 'Income'),
                    SizedBox(width: AppSpacing.md),
                    _LegendDot(
                      color: AppColors.danger,
                      label: 'Expense',
                    ),
                  ],
                )
              : Row(
                  children: [
                    _LegendValue(
                      color: AppColors.success,
                      label: selectedBucket.label,
                      value: currency.formatCompact(selectedBucket.income),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _LegendValue(
                      color: AppColors.danger,
                      label: 'Spent',
                      value: currency.formatCompact(selectedBucket.expense),
                    ),
                  ],
                ),
        ),
        SizedBox(
          height: widget.height,
          child: GestureDetector(
            onTapDown: (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final local = box.globalToLocal(details.globalPosition);
              final width = box.size.width;
              final index = ((local.dx / width) * buckets.length).floor();
              setState(() {
                _selectedIndex = index.clamp(0, buckets.length - 1);
              });
            },
            onTapUp: (_) {
              Future.delayed(
                const Duration(milliseconds: 2200),
                () {
                  if (mounted) setState(() => _selectedIndex = null);
                },
              );
            },
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: AppDurations.reveal,
              curve: AppCurves.easeOutQuint,
              builder: (context, progress, _) {
                return CustomPaint(
                  painter: _IncomeExpensePainter(
                    buckets: buckets,
                    maxValue: maxValue,
                    progress: progress,
                    selectedIndex: _selectedIndex,
                  ),
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < buckets.length; i++)
              Expanded(
                child: Text(
                  buckets[i].label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.label.copyWith(
                    fontSize: 10,
                    color: i == _selectedIndex
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: i == _selectedIndex
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 11)),
      ],
    );
  }
}

class _LegendValue extends StatelessWidget {
  const _LegendValue({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label · $value',
          style: AppTextStyles.label.copyWith(
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _IncomeExpensePainter extends CustomPainter {
  _IncomeExpensePainter({
    required this.buckets,
    required this.maxValue,
    required this.progress,
    required this.selectedIndex,
  });

  final List<PeriodBucket> buckets;
  final double maxValue;
  final double progress;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    const topPad = 8.0;
    const bottomPad = 4.0;
    final chartHeight = size.height - topPad - bottomPad;
    final baselineY = size.height - bottomPad;

    final gridPaint = Paint()
      ..color = AppColors.border.withAlpha(80)
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = baselineY - (chartHeight / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    canvas.drawLine(
      Offset(0, baselineY),
      Offset(size.width, baselineY),
      gridPaint,
    );

    if (maxValue <= 0) return;

    final groupWidth = size.width / buckets.length;
    final barWidth = (groupWidth * 0.32).clamp(6.0, 22.0).toDouble();
    final gap = (groupWidth - barWidth * 2) / 3;

    for (var i = 0; i < buckets.length; i++) {
      final bucket = buckets[i];
      final groupX = groupWidth * i;
      final isSelected = i == selectedIndex;

      final incomeH = (bucket.income / maxValue) * chartHeight * progress;
      final expenseH = (bucket.expense / maxValue) * chartHeight * progress;

      _paintBar(
        canvas,
        rect: Rect.fromLTWH(
          groupX + gap,
          baselineY - incomeH,
          barWidth,
          incomeH,
        ),
        color: AppColors.success,
        emphasised: isSelected,
      );
      _paintBar(
        canvas,
        rect: Rect.fromLTWH(
          groupX + gap * 2 + barWidth,
          baselineY - expenseH,
          barWidth,
          expenseH,
        ),
        color: AppColors.danger,
        emphasised: isSelected,
      );
    }
  }

  void _paintBar(
    Canvas canvas, {
    required Rect rect,
    required Color color,
    required bool emphasised,
  }) {
    if (rect.height <= 0) return;
    final paint = Paint()
      ..color = emphasised
          ? Color.lerp(color, Colors.white, 0.12)!
          : color.withAlpha(emphasised ? 255 : 220)
      ..isAntiAlias = true;
    final rounded = RRect.fromRectAndCorners(
      rect,
      topLeft: const Radius.circular(6),
      topRight: const Radius.circular(6),
      bottomLeft: const Radius.circular(2),
      bottomRight: const Radius.circular(2),
    );
    canvas.drawRRect(rounded, paint);
  }

  @override
  bool shouldRepaint(covariant _IncomeExpensePainter old) {
    return old.buckets != buckets ||
        old.progress != progress ||
        old.selectedIndex != selectedIndex ||
        old.maxValue != maxValue;
  }
}
