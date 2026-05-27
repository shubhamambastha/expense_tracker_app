import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../config/design_tokens.dart';
import '../../../services/currency_settings.dart';
import '../../../utils/analytics_aggregations.dart';

/// Multi-line area chart over a list of [PeriodBucket]s.
///
/// Renders an expense-line baseline with an income-line overlay and a soft
/// savings tint above the X-axis. Tap-to-inspect surfaces the exact bucket
/// totals for that period.
///
/// The widget adapts to whatever vertical space the parent gives it — the
/// drawing area uses [Expanded], so the chart fits cleanly into a fixed-
/// height [PageView] or any constrained parent.
class TrendLineChart extends StatefulWidget {
  const TrendLineChart({
    super.key,
    required this.buckets,
    this.showIncome = true,
  });

  final List<PeriodBucket> buckets;
  final bool showIncome;

  @override
  State<TrendLineChart> createState() => _TrendLineChartState();
}

class _TrendLineChartState extends State<TrendLineChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final buckets = widget.buckets;
    if (buckets.length < 2) {
      return const Center(
        child: Text(
          'Add a few more months to unlock the trend view.',
          style: AppTextStyles.bodySmall,
        ),
      );
    }

    final maxValue = buckets.fold<double>(
      0,
      (m, b) => math.max(m, math.max(b.income, b.expense)),
    );

    final currency = CurrencySettings.instance;
    final selected = _selectedIndex;
    final selectedBucket = (selected != null && selected < buckets.length)
        ? buckets[selected]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 22,
          child: selectedBucket == null
              ? Row(
                  children: [
                    if (widget.showIncome) ...[
                      const _LegendDot(
                        color: AppColors.success,
                        label: 'Income',
                      ),
                      const SizedBox(width: AppSpacing.md),
                    ],
                    const _LegendDot(
                      color: AppColors.danger,
                      label: 'Expense',
                    ),
                  ],
                )
              : Text(
                  '${selectedBucket.label} · '
                  '${currency.formatCompact(selectedBucket.expense)} spent'
                  '${widget.showIncome ? ' · ${currency.formatCompact(selectedBucket.income)} earned' : ''}',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
        ),
        Expanded(
          child: GestureDetector(
            onTapDown: (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final local = box.globalToLocal(details.globalPosition);
              final width = box.size.width;
              final idx = ((local.dx / width) * buckets.length)
                  .floor()
                  .clamp(0, buckets.length - 1);
              setState(() => _selectedIndex = idx);
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
                  painter: _TrendLinePainter(
                    buckets: buckets,
                    maxValue: maxValue,
                    progress: progress,
                    selectedIndex: _selectedIndex,
                    showIncome: widget.showIncome,
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
                  // Show every other label when crowded.
                  buckets.length > 8 && i.isOdd ? '' : buckets[i].label,
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

class _TrendLinePainter extends CustomPainter {
  _TrendLinePainter({
    required this.buckets,
    required this.maxValue,
    required this.progress,
    required this.selectedIndex,
    required this.showIncome,
  });

  final List<PeriodBucket> buckets;
  final double maxValue;
  final double progress;
  final int? selectedIndex;
  final bool showIncome;

  @override
  void paint(Canvas canvas, Size size) {
    const topPad = 10.0;
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

    Offset positionFor(int i, double value) {
      final x = buckets.length == 1
          ? size.width / 2
          : (i / (buckets.length - 1)) * size.width;
      final norm = value / maxValue;
      return Offset(x, baselineY - norm * chartHeight * progress);
    }

    final expensePoints = <Offset>[
      for (var i = 0; i < buckets.length; i++) positionFor(i, buckets[i].expense),
    ];
    final incomePoints = showIncome
        ? <Offset>[
            for (var i = 0; i < buckets.length; i++)
              positionFor(i, buckets[i].income),
          ]
        : const <Offset>[];

    _drawLineWithFill(
      canvas,
      points: expensePoints,
      color: AppColors.danger,
      baselineY: baselineY,
      chartHeight: chartHeight,
    );
    if (showIncome) {
      _drawLineWithFill(
        canvas,
        points: incomePoints,
        color: AppColors.success,
        baselineY: baselineY,
        chartHeight: chartHeight,
      );
    }

    final highlight = selectedIndex;
    if (highlight != null && highlight >= 0 && highlight < buckets.length) {
      final x = expensePoints[highlight].dx;
      canvas.drawLine(
        Offset(x, topPad),
        Offset(x, baselineY),
        Paint()
          ..color = AppColors.primary.withAlpha(60)
          ..strokeWidth = 1,
      );
      _drawPoint(canvas, expensePoints[highlight], AppColors.danger);
      if (showIncome) {
        _drawPoint(canvas, incomePoints[highlight], AppColors.success);
      }
    }
  }

  void _drawLineWithFill(
    Canvas canvas, {
    required List<Offset> points,
    required Color color,
    required double baselineY,
    required double chartHeight,
  }) {
    if (points.length < 2) return;
    final path = _smoothPath(points);
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, baselineY)
      ..lineTo(points.first.dx, baselineY)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          Offset(0, chartHeight),
          [color.withAlpha(45), color.withAlpha(6)],
          [0.0, 1.0],
        )
        ..isAntiAlias = true,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
  }

  void _drawPoint(Canvas canvas, Offset point, Color color) {
    canvas.drawCircle(
      point,
      5,
      Paint()..color = color.withAlpha(40),
    );
    canvas.drawCircle(
      point,
      3.5,
      Paint()..color = color,
    );
    canvas.drawCircle(
      point,
      3.5,
      Paint()
        ..color = AppColors.background
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  Path _smoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter old) {
    return old.buckets != buckets ||
        old.progress != progress ||
        old.selectedIndex != selectedIndex ||
        old.maxValue != maxValue ||
        old.showIncome != showIncome;
  }
}
