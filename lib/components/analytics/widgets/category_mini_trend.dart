import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../config/design_tokens.dart';

/// 6-month sparkline used inside an expanded category insight.
class CategoryMiniTrend extends StatelessWidget {
  const CategoryMiniTrend({
    super.key,
    required this.monthlyTotals,
    required this.color,
    this.height = 38,
  });

  final List<double> monthlyTotals;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (monthlyTotals.length < 2) {
      return SizedBox(height: height);
    }
    final max = monthlyTotals.fold<double>(0, math.max);
    if (max <= 0) {
      return SizedBox(height: height);
    }
    return SizedBox(
      height: height,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: AppDurations.reveal,
        curve: AppCurves.easeOutQuint,
        builder: (context, t, _) {
          return CustomPaint(
            painter: _MiniTrendPainter(
              values: monthlyTotals,
              maxValue: max,
              color: color,
              progress: t,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _MiniTrendPainter extends CustomPainter {
  _MiniTrendPainter({
    required this.values,
    required this.maxValue,
    required this.color,
    required this.progress,
  });

  final List<double> values;
  final double maxValue;
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || maxValue <= 0) return;
    final padBottom = 2.0;
    final h = size.height - padBottom;
    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          (i / (values.length - 1)) * size.width,
          (h - (values[i] / maxValue) * (h - 4)) * 1.0,
        ),
    ];

    final smooth = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      smooth.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    smooth.lineTo(points.last.dx, points.last.dy);

    canvas.drawPath(
      smooth,
      Paint()
        ..color = color.withAlpha((180 * progress).round().clamp(0, 255))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );

    final last = points.last;
    canvas.drawCircle(
      last,
      2.6,
      Paint()..color = color.withAlpha(220),
    );
  }

  @override
  bool shouldRepaint(covariant _MiniTrendPainter old) {
    return old.values != values ||
        old.progress != progress ||
        old.color != color ||
        old.maxValue != maxValue;
  }
}
