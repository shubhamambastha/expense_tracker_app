import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../../models/expense.dart';
import '../../utils/constants.dart';

/// Shared palette for category charts (matches expense list accents).
const kAnalyticsChartColors = <Color>[
  Color(0xFF4F8EF7),
  Color(0xFF47B881),
  Color(0xFFF8B229),
  Color(0xFF8E5AF7),
  Color(0xFFF15C5C),
  Color(0xFF3FB0AC),
  Color(0xFFF88D42),
];

Color analyticsColorForCategory(String category) {
  final index = AppConstants.expenseCategories.indexOf(category);
  if (index >= 0 && index < kAnalyticsChartColors.length) {
    return kAnalyticsChartColors[index];
  }
  return kAnalyticsChartColors[category.hashCode.abs() % kAnalyticsChartColors.length];
}

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

  @override
  Widget build(BuildContext context) {
    final currentExpenses = _currentMonthExpenses;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoryTotals = _categoryTotals;
    final sortedCategories = _sortedCategoryTotals;
    final currency = intl.NumberFormat.simpleCurrency();
    final topCategory = sortedCategories.isEmpty ? null : sortedCategories.first;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(90)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currentExpenses.isEmpty)
              _EmptyAnalyticsState(colorScheme: colorScheme)
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
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currency.format(_currentMonthTotal),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary.withAlpha(28),
                          colorScheme.tertiary.withAlpha(18),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.insights_rounded,
                      color: colorScheme.primary,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
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
              const SizedBox(height: 22),
              _ChartSectionHeader(
                title: 'Spending mix',
                subtitle: topCategory == null
                    ? null
                    : 'Top: ${topCategory.key}',
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 172,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 11,
                      child: CategoryPieChart(
                        categoryTotals: categoryTotals,
                        sortedEntries: sortedCategories,
                        total: _currentMonthTotal,
                        colorForCategory: analyticsColorForCategory,
                        trackColor: colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 10,
                      child: _CategoryLegend(
                        entries: sortedCategories,
                        total: _currentMonthTotal,
                        colorForCategory: analyticsColorForCategory,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _ChartSectionHeader(
                title: 'Daily rhythm',
                subtitle: 'Tap a point for details',
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 128,
                child: DailySpendingChart(
                  dailyTotals: _dailyTotals,
                  todayDay: _now.day,
                  lineColor: colorScheme.primary,
                  fillColor: colorScheme.primary,
                  gridColor: colorScheme.outlineVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyAnalyticsState extends StatelessWidget {
  const _EmptyAnalyticsState({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.pie_chart_outline_rounded,
              color: colorScheme.primary.withAlpha(180),
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No spending this month yet',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add expenses to unlock your category breakdown and daily trend.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartSectionHeader extends StatelessWidget {
  const _ChartSectionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
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
        color: colorScheme.surfaceContainerHighest.withAlpha(90),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
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
    final currency = intl.NumberFormat.compactCurrency();
    final visibleEntries = entries.take(4).toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: visibleEntries.map((entry) {
        final share = total <= 0.0 ? 0.0 : entry.value / total;
        final color = colorForCategory(entry.key);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withAlpha(80),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${(share * 100).round()}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: share,
                  minHeight: 4,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                currency.format(entry.value),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
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
    required this.sortedEntries,
    required this.total,
    required this.colorForCategory,
    required this.trackColor,
  });

  final Map<String, double> categoryTotals;
  final List<MapEntry<String, double>> sortedEntries;
  final double total;
  final Color Function(String category) colorForCategory;
  final Color trackColor;

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  OverlayEntry? _tooltipEntry;
  String? _selectedCategory;

  int get _animationKey => Object.hashAll(
    widget.sortedEntries.map((e) => '${e.key}:${e.value}'),
  );

  @override
  void dispose() {
    _hideTooltip();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: (_) => Future.delayed(const Duration(seconds: 2), _hideTooltip),
      child: TweenAnimationBuilder<double>(
        key: ValueKey(_animationKey),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, progress, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _CategoryPiePainter(
                  sortedEntries: widget.sortedEntries,
                  colorForCategory: widget.colorForCategory,
                  trackColor: widget.trackColor,
                  progress: progress,
                  selectedCategory: _selectedCategory,
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _onTapDown(TapDownDetails details) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final category = _categoryAtPosition(localPosition, renderBox.size);
    setState(() => _selectedCategory = category);

    if (category == null) {
      _hideTooltip();
      return;
    }
    _showTooltip(context, details.globalPosition, category);
  }

  String? _categoryAtPosition(Offset position, Size size) {
    if (widget.sortedEntries.isEmpty || widget.total <= 0) return null;

    final radius = size.shortestSide * 0.44;
    final innerRadius = radius * 0.62;
    final center = Offset(size.width / 2, size.height / 2);
    final tapOffset = position - center;
    if (tapOffset.distance > radius || tapOffset.distance < innerRadius) {
      return null;
    }

    var tapAngle = math.atan2(tapOffset.dy, tapOffset.dx);
    tapAngle = (tapAngle + math.pi / 2 + 2 * math.pi) % (2.0 * math.pi);

    const gap = _CategoryPiePainter.segmentGapRadians;
    var startAngle = 0.0;
    for (final entry in widget.sortedEntries) {
      final sweepAngle = (entry.value / widget.total) * 2.0 * math.pi - gap;
      final endAngle = startAngle + sweepAngle;
      if (tapAngle >= startAngle && tapAngle < endAngle) {
        return entry.key;
      }
      startAngle = endAngle + gap;
    }

    return widget.sortedEntries.lastOrNull?.key;
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

    final share = widget.total <= 0 ? 0 : (amount / widget.total) * 100;
    final colorScheme = Theme.of(context).colorScheme;

    _tooltipEntry = OverlayEntry(
      builder: (context) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final left = math.min(globalPosition.dx + 8, screenWidth - 190);

        return Positioned(
          left: math.max(12, left),
          top: globalPosition.dy - 52,
          child: IgnorePointer(
            child: Material(
              color: Colors.transparent,
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.inverseSurface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withAlpha(60),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: widget.colorForCategory(category),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            category,
                            style: TextStyle(
                              color: colorScheme.onInverseSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${intl.NumberFormat.simpleCurrency().format(amount)} · ${share.round()}%',
                            style: TextStyle(
                              color: colorScheme.onInverseSurface.withAlpha(200),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_tooltipEntry!);
  }

  void _hideTooltip() {
    _tooltipEntry?.remove();
    _tooltipEntry = null;
  }
}

class _CategoryPiePainter extends CustomPainter {
  _CategoryPiePainter({
    required this.sortedEntries,
    required this.colorForCategory,
    required this.trackColor,
    required this.progress,
    this.selectedCategory,
  });

  final List<MapEntry<String, double>> sortedEntries;
  final Color Function(String category) colorForCategory;
  final Color trackColor;
  final double progress;
  final String? selectedCategory;

  static const segmentGapRadians = 0.035;

  @override
  void paint(Canvas canvas, Size size) {
    final total = sortedEntries.fold<double>(
      0.0,
      (sum, entry) => sum + entry.value,
    );
    if (total <= 0) return;

    final outerRadius = size.shortestSide * 0.44;
    final innerRadius = outerRadius * 0.62;
    final strokeWidth = outerRadius - innerRadius;
    final radius = innerRadius + strokeWidth / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor.withAlpha(200)
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius, trackPaint);

    final segmentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    var startAngle = -math.pi / 2;
    for (final entry in sortedEntries) {
      final fullSweep = (entry.value / total) * 2.0 * math.pi - segmentGapRadians;
      final sweep = fullSweep * progress;
      final isSelected = entry.key == selectedCategory;
      final color = colorForCategory(entry.key);

      segmentPaint
        ..color = color
        ..strokeWidth = isSelected ? strokeWidth + 3 : strokeWidth
        ..maskFilter = isSelected
            ? MaskFilter.blur(BlurStyle.normal, 2)
            : null;

      if (isSelected) {
        segmentPaint.color = Color.lerp(color, Colors.white, 0.12)!;
      }

      canvas.drawArc(rect, startAngle, sweep, false, segmentPaint);
      startAngle += fullSweep + segmentGapRadians;
    }
  }

  @override
  bool shouldRepaint(covariant _CategoryPiePainter oldDelegate) {
    return oldDelegate.sortedEntries != sortedEntries ||
        oldDelegate.progress != progress ||
        oldDelegate.selectedCategory != selectedCategory ||
        oldDelegate.trackColor != trackColor;
  }
}

class DailySpendingChart extends StatefulWidget {
  const DailySpendingChart({
    super.key,
    required this.dailyTotals,
    required this.todayDay,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
  });

  final List<double> dailyTotals;
  final int todayDay;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;

  @override
  State<DailySpendingChart> createState() => _DailySpendingChartState();
}

class _DailySpendingChartState extends State<DailySpendingChart> {
  int? _selectedDayIndex;

  int get _animationKey => Object.hashAll(widget.dailyTotals);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      fontSize: 10,
    );
    final totalDays = widget.dailyTotals.length;
    final midpoint = (totalDays / 2).ceil();
    final selectedIndex = _selectedDayIndex;
    final selectedAmount = selectedIndex != null &&
            selectedIndex >= 0 &&
            selectedIndex < widget.dailyTotals.length
        ? widget.dailyTotals[selectedIndex]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selectedAmount != null && selectedAmount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'Day ${selectedIndex! + 1}: ${intl.NumberFormat.simpleCurrency().format(selectedAmount)}',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ),
        Expanded(
          child: GestureDetector(
            onTapDown: (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final local = box.globalToLocal(details.globalPosition);
              final chartWidth = box.size.width;
              final index = ((local.dx / chartWidth) * widget.dailyTotals.length)
                  .floor()
                  .clamp(0, widget.dailyTotals.length - 1);
              setState(() => _selectedDayIndex = index);
            },
            onTapUp: (_) {
              Future.delayed(
                const Duration(milliseconds: 2200),
                () {
                  if (mounted) setState(() => _selectedDayIndex = null);
                },
              );
            },
            child: TweenAnimationBuilder<double>(
              key: ValueKey(_animationKey),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, progress, _) {
                return CustomPaint(
                  painter: _DailySpendingPainter(
                    dailyTotals: widget.dailyTotals,
                    todayDay: widget.todayDay,
                    lineColor: widget.lineColor,
                    fillColor: widget.fillColor,
                    gridColor: widget.gridColor,
                    progress: progress,
                    selectedDayIndex: _selectedDayIndex,
                  ),
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('1', style: labelStyle),
            Text('$midpoint', style: labelStyle),
            Text('$totalDays', style: labelStyle),
          ],
        ),
      ],
    );
  }
}

class _DailySpendingPainter extends CustomPainter {
  _DailySpendingPainter({
    required this.dailyTotals,
    required this.todayDay,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
    required this.progress,
    this.selectedDayIndex,
  });

  final List<double> dailyTotals;
  final int todayDay;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;
  final double progress;
  final int? selectedDayIndex;

  @override
  void paint(Canvas canvas, Size size) {
    const bottomPad = 4.0;
    final chartHeight = size.height - bottomPad;
    final baselineY = chartHeight;

    final gridPaint = Paint()
      ..color = gridColor.withAlpha(90)
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = baselineY - (chartHeight / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    canvas.drawLine(Offset(0, baselineY), Offset(size.width, baselineY), gridPaint);

    if (dailyTotals.isEmpty) return;

    final maxTotal = dailyTotals.reduce(math.max);
    if (maxTotal <= 0) return;

    final points = <Offset>[];
    for (var i = 0; i < dailyTotals.length; i++) {
      final x = dailyTotals.length == 1
          ? size.width / 2
          : (i / (dailyTotals.length - 1)) * size.width;
      final normalized = dailyTotals[i] / maxTotal;
      final y = baselineY - normalized * (chartHeight - 12) * progress;
      points.add(Offset(x, y));
    }

    final visibleCount = math.max(2, (points.length * progress).round());
    final visiblePoints = points.take(visibleCount).toList();
    if (visiblePoints.length < 2) return;

    final smoothPath = _buildSmoothPath(visiblePoints);
    final fillPath = Path.from(smoothPath)
      ..lineTo(visiblePoints.last.dx, baselineY)
      ..lineTo(visiblePoints.first.dx, baselineY)
      ..close();

    final fillShader = ui.Gradient.linear(
      Offset(0, 0),
      Offset(0, chartHeight),
      [fillColor.withAlpha(55), fillColor.withAlpha(8)],
      [0.0, 1.0],
    );
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = fillShader
        ..isAntiAlias = true,
    );

    canvas.drawPath(
      smoothPath,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );

    final todayIndex = todayDay - 1;
    if (todayIndex >= 0 && todayIndex < points.length) {
      final todayPoint = points[todayIndex];
      canvas.drawLine(
        Offset(todayPoint.dx, baselineY - 2),
        Offset(todayPoint.dx, todayPoint.dy - 6),
        Paint()
          ..color = lineColor.withAlpha(70)
          ..strokeWidth = 1,
      );
    }

    final highlightIndex = selectedDayIndex ?? todayIndex;
    if (highlightIndex >= 0 && highlightIndex < points.length) {
      final p = points[highlightIndex];
      if (dailyTotals[highlightIndex] > 0) {
        canvas.drawCircle(
          p,
          5,
          Paint()
            ..color = lineColor.withAlpha(40)
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          p,
          3.5,
          Paint()
            ..color = lineColor
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          p,
          3.5,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  Path _buildSmoothPath(List<Offset> points) {
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
  bool shouldRepaint(covariant _DailySpendingPainter oldDelegate) {
    return oldDelegate.dailyTotals != dailyTotals ||
        oldDelegate.progress != progress ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.selectedDayIndex != selectedDayIndex ||
        oldDelegate.todayDay != todayDay;
  }
}
