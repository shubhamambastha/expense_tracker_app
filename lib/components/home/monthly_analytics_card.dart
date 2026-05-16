import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../../models/expense.dart';
import '../../utils/constants.dart';

class MonthlyAnalyticsCard extends StatelessWidget {
  const MonthlyAnalyticsCard({super.key, required this.expenses});

  final List<Expense> expenses;

  DateTime get _now => DateTime.now();

  List<Expense> get _currentMonthExpenses {
    return expenses.where((expense) {
      return expense.date.year == _now.year && expense.date.month == _now.month;
    }).toList();
  }

  double get _currentMonthTotal {
    return _currentMonthExpenses.fold<double>(
      0.0,
      (double sum, expense) => sum + expense.amount,
    );
  }

  Map<String, double> get _categoryTotals {
    final totals = <String, double>{};
    for (final expense in _currentMonthExpenses) {
      totals[expense.category] =
          (totals[expense.category] ?? 0.0) + expense.amount;
    }
    return totals;
  }

  List<MapEntry<String, double>> get _sortedCategoryTotals {
    final entries = _categoryTotals.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  int get _activeDays {
    return _dailyTotals.where((total) => total > 0.0).length;
  }

  int get _daysInMonth {
    final nextMonth = DateTime(_now.year, _now.month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1)).day;
  }

  List<double> get _dailyTotals {
    final totals = List<double>.filled(_daysInMonth, 0.0);
    for (final expense in _currentMonthExpenses) {
      final index = expense.date.day - 1;
      if (index >= 0 && index < totals.length) {
        totals[index] += expense.amount;
      }
    }
    return totals;
  }

  String get _monthLabel {
    return intl.DateFormat('MMMM yyyy').format(_now);
  }

  static const _chartColors = <Color>[
    Color(0xFF4F8EF7),
    Color(0xFF47B881),
    Color(0xFFF8B229),
    Color(0xFF8E5AF7),
    Color(0xFFF15C5C),
    Color(0xFF3FB0AC),
    Color(0xFFF88D42),
  ];

  Color _colorForCategory(String category) {
    final index = AppConstants.expenseCategories.indexOf(category);
    if (index >= 0 && index < _chartColors.length) {
      return _chartColors[index];
    }
    return _chartColors[category.hashCode.abs() % _chartColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final currentExpenses = _currentMonthExpenses;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoryTotals = _categoryTotals;
    final sortedCategories = _sortedCategoryTotals;
    final currency = intl.NumberFormat.simpleCurrency();

    return Card(
      elevation: 1,
      color: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currentExpenses.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Add expenses to see your current month analytics here.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _monthLabel,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currency.format(_currentMonthTotal),
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.auto_graph_rounded,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _AnalyticsStat(
                      icon: Icons.grid_view_rounded,
                      value: categoryTotals.length.toString(),
                      label: 'categories',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AnalyticsStat(
                      icon: Icons.calendar_today_rounded,
                      value: _activeDays.toString(),
                      label: 'active days',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 160,
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: CategoryPieChart(
                        categoryTotals: categoryTotals,
                        colorForCategory: _colorForCategory,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 4,
                      child: _CategoryLegend(
                        entries: sortedCategories,
                        total: _currentMonthTotal,
                        colorForCategory: _colorForCategory,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Daily rhythm',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 104,
                child: DailySpendingChart(
                  dailyTotals: _dailyTotals,
                  chartColor: colorScheme.tertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnalyticsStat extends StatelessWidget {
  const _AnalyticsStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(115),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryLegend extends StatelessWidget {
  const _CategoryLegend({
    required this.entries,
    required this.total,
    required this.colorForCategory,
  });

  final List<MapEntry<String, double>> entries;
  final double total;
  final Color Function(String category) colorForCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final visibleEntries = entries.take(4).toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: visibleEntries.map((entry) {
        final share = total <= 0.0 ? 0.0 : (entry.value / total) * 100;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: colorForCategory(entry.key),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.key,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${share.round()}%',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class CategoryPieChart extends StatefulWidget {
  const CategoryPieChart({
    super.key,
    required this.categoryTotals,
    required this.colorForCategory,
  });

  final Map<String, double> categoryTotals;
  final Color Function(String category) colorForCategory;

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  OverlayEntry? _tooltipEntry;

  @override
  void dispose() {
    _hideTooltip();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        final renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(details.globalPosition);
        final category = _categoryAtPosition(localPosition, renderBox.size);
        if (category == null) {
          _hideTooltip();
          return;
        }
        _showTooltip(context, details.globalPosition, category);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _CategoryPiePainter(
              categoryTotals: widget.categoryTotals,
              colorForCategory: widget.colorForCategory,
            ),
          );
        },
      ),
    );
  }

  String? _categoryAtPosition(Offset position, Size size) {
    final total = widget.categoryTotals.values.fold<double>(
      0.0,
      (sum, value) => sum + value,
    );
    if (total <= 0.0) return null;

    final radius = size.shortestSide * 0.46;
    final innerRadius = radius * 0.58;
    final center = Offset(size.width / 2, size.height / 2);
    final tapOffset = position - center;
    if (tapOffset.distance > radius || tapOffset.distance < innerRadius) {
      return null;
    }

    var tapAngle = math.atan2(tapOffset.dy, tapOffset.dx);
    tapAngle = (tapAngle + math.pi / 2) % (2.0 * math.pi);

    var startAngle = 0.0;
    for (final entry in widget.categoryTotals.entries) {
      final sweepAngle = (entry.value / total) * 2.0 * math.pi;
      final endAngle = startAngle + sweepAngle;
      if (tapAngle >= startAngle && tapAngle < endAngle) {
        return entry.key;
      }
      startAngle = endAngle;
    }

    return widget.categoryTotals.entries.lastOrNull?.key;
  }

  void _showTooltip(
    BuildContext context,
    Offset globalPosition,
    String category,
  ) {
    _hideTooltip();

    final overlay = Overlay.of(context);
    final amount = widget.categoryTotals[category];
    if (amount == null) return;

    _tooltipEntry = OverlayEntry(
      builder: (context) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final left = math.min(globalPosition.dx + 12, screenWidth - 178);
        return Positioned(
          left: math.max(12, left),
          top: globalPosition.dy - 44,
          child: IgnorePointer(
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: screenWidth - 24),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: widget.colorForCategory(category),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '$category: ${intl.NumberFormat.simpleCurrency().format(amount)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_tooltipEntry!);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _hideTooltip();
    });
  }

  void _hideTooltip() {
    _tooltipEntry?.remove();
    _tooltipEntry = null;
  }
}

class _CategoryPiePainter extends CustomPainter {
  _CategoryPiePainter({
    required this.categoryTotals,
    required this.colorForCategory,
  });

  final Map<String, double> categoryTotals;
  final Color Function(String category) colorForCategory;

  @override
  void paint(Canvas canvas, Size size) {
    final total = categoryTotals.values.fold<double>(
      0.0,
      (double sum, value) => sum + value,
    );
    final outerRadius = size.shortestSide * 0.46;
    final innerRadius = outerRadius * 0.58;
    final strokeWidth = outerRadius - innerRadius;
    final radius = innerRadius + strokeWidth / 2;
    final center = Offset(size.width / 2, size.height / 2);

    var startAngle = -math.pi / 2;
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = const Color(0xFFE6ECE9)
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius, trackPaint);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true;

    for (final entry in categoryTotals.entries) {
      final sweepAngle = total <= 0.0
          ? 0.0
          : (entry.value / total) * 2.0 * math.pi;
      paint.color = colorForCategory(entry.key);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _CategoryPiePainter oldDelegate) {
    return oldDelegate.categoryTotals != categoryTotals;
  }
}

class DailySpendingChart extends StatelessWidget {
  const DailySpendingChart({
    super.key,
    required this.dailyTotals,
    required this.chartColor,
  });

  final List<double> dailyTotals;
  final Color chartColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CustomPaint(
      painter: _DailySpendingPainter(
        dailyTotals: dailyTotals,
        chartColor: chartColor,
        guideColor: colorScheme.outlineVariant,
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(child: SizedBox()),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _buildDateLabels(context),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDateLabels(BuildContext context) {
    final totalDays = dailyTotals.length;
    final midpoint = (totalDays / 2).ceil();
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    return [
      Text('1', style: labelStyle),
      Text('$midpoint', style: labelStyle),
      Text('$totalDays', style: labelStyle),
    ];
  }
}

class _DailySpendingPainter extends CustomPainter {
  _DailySpendingPainter({
    required this.dailyTotals,
    required this.chartColor,
    required this.guideColor,
  });

  final List<double> dailyTotals;
  final Color chartColor;
  final Color guideColor;

  @override
  void paint(Canvas canvas, Size size) {
    final chartHeight = size.height - 20;
    final baselineY = chartHeight + 1;
    final guidePaint = Paint()
      ..color = guideColor.withAlpha(150)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, baselineY),
      Offset(size.width, baselineY),
      guidePaint,
    );

    if (dailyTotals.isEmpty) return;

    final maxTotal = dailyTotals.reduce((double a, double b) => a > b ? a : b);
    if (maxTotal <= 0.0) return;

    final paint = Paint()
      ..color = chartColor.withAlpha((0.82 * 255).round())
      ..isAntiAlias = true;
    final barWidth = math.max(4.0, size.width / (dailyTotals.length * 3.2));
    final spacing =
        (size.width - dailyTotals.length * barWidth) / (dailyTotals.length + 1);

    for (var index = 0; index < dailyTotals.length; index++) {
      final value = dailyTotals[index];
      if (value <= 0.0) continue;

      final left = spacing + index * (barWidth + spacing);
      final barHeight = math.max(8.0, (value / maxTotal) * (chartHeight - 4));
      final top = baselineY - barHeight;
      final rect = Rect.fromLTWH(left, top, barWidth, barHeight);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(barWidth / 2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DailySpendingPainter oldDelegate) {
    return oldDelegate.dailyTotals != dailyTotals ||
        oldDelegate.chartColor != chartColor ||
        oldDelegate.guideColor != guideColor;
  }
}
