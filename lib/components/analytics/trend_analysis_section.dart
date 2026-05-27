import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../services/currency_settings.dart';
import '../../utils/analytics_aggregations.dart';
import '../home/dashboard/dashboard_section_header.dart';
import 'widgets/analytics_section_card.dart';
import 'widgets/trend_line_chart.dart';

/// Long-term financial pattern visibility — last 12 months by default,
/// swipable between three lenses (Net, Income, Expense). Keeps the chart
/// playful without becoming a BI grid.
class TrendAnalysisSection extends StatefulWidget {
  const TrendAnalysisSection({
    super.key,
    required this.buckets,
  });

  final List<PeriodBucket> buckets;

  @override
  State<TrendAnalysisSection> createState() => _TrendAnalysisSectionState();
}

class _TrendAnalysisSectionState extends State<TrendAnalysisSection> {
  late final PageController _pageController;
  int _pageIndex = 0;

  static const _lenses = [
    _TrendLens(
      label: 'Money flow',
      subtitle: 'Income & expense over time',
      hint: 'Tap a point to inspect a month.',
      includeIncome: true,
    ),
    _TrendLens(
      label: 'Spending only',
      subtitle: 'How outflow has moved',
      hint: 'Swipe back for the full picture.',
      includeIncome: false,
    ),
    _TrendLens(
      label: 'Savings trend',
      subtitle: 'What stayed each month',
      hint: 'Green = kept, red = overspent.',
      // Savings mode maps net → income/expense series so the chart's
      // existing two-line layout doubles as a savings-vs-loss visual.
      includeIncome: true,
      mode: _TrendMode.savings,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buckets = widget.buckets;
    final hasData = buckets.where((b) => b.income > 0 || b.expense > 0).isNotEmpty;
    if (!hasData) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DashboardSectionHeader(title: 'Trend Analysis'),
          const SizedBox(height: AppSpacing.md),
          AnalyticsSectionCard(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.show_chart_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Expanded(
                  child: Text(
                    'A few months of activity unlocks the long-term trend view.',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final lens = _lenses[_pageIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionHeader(
          title: 'Trend Analysis',
          subtitle: lens.hint,
        ),
        const SizedBox(height: AppSpacing.md),
        AnalyticsSectionCard(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lens.label,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lens.subtitle,
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  _PageDots(
                    count: _lenses.length,
                    index: _pageIndex,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 200,
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _lenses.length,
                  onPageChanged: (page) {
                    setState(() => _pageIndex = page);
                  },
                  itemBuilder: (context, index) {
                    final entry = _lenses[index];
                    final mappedBuckets = _mapBuckets(buckets, entry.mode);
                    return TrendLineChart(
                      buckets: mappedBuckets,
                      showIncome: entry.includeIncome,
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _TrendInsightFooter(buckets: buckets, lens: lens),
            ],
          ),
        ),
      ],
    );
  }

  List<PeriodBucket> _mapBuckets(
    List<PeriodBucket> source,
    _TrendMode mode,
  ) {
    switch (mode) {
      case _TrendMode.moneyFlow:
        return source;
      case _TrendMode.savings:
        // Repurpose the bar chart's expense series as |negative net| and
        // the income series as |positive net| so positive months stay
        // green and negative months read as red.
        return source
            .map(
              (b) => PeriodBucket(
                label: b.label,
                start: b.start,
                end: b.end,
                income: b.net > 0 ? b.net : 0,
                expense: b.net < 0 ? -b.net : 0,
              ),
            )
            .toList();
    }
  }
}

class _TrendLens {
  const _TrendLens({
    required this.label,
    required this.subtitle,
    required this.hint,
    required this.includeIncome,
    this.mode = _TrendMode.moneyFlow,
  });

  final String label;
  final String subtitle;
  final String hint;
  final bool includeIncome;
  final _TrendMode mode;
}

enum _TrendMode { moneyFlow, savings }

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++) ...[
          AnimatedContainer(
            duration: AppDurations.micro,
            curve: AppCurves.spring,
            width: i == index ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == index
                  ? AppColors.primary
                  : AppColors.border,
              borderRadius: AppRadii.pillRadius,
            ),
          ),
          if (i != count - 1) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

class _TrendInsightFooter extends StatelessWidget {
  const _TrendInsightFooter({required this.buckets, required this.lens});

  final List<PeriodBucket> buckets;
  final _TrendLens lens;

  @override
  Widget build(BuildContext context) {
    if (buckets.length < 2) return const SizedBox.shrink();
    final currency = CurrencySettings.instance;
    final last = buckets.last;
    final prev = buckets[buckets.length - 2];
    String message;
    Color tone = AppColors.secondary;
    IconData icon = Icons.timeline_rounded;

    switch (lens.mode) {
      case _TrendMode.moneyFlow:
        if (last.expense > prev.expense * 1.2) {
          message = 'Expenses jumped in ${last.label} — '
              '${currency.formatCompact(last.expense - prev.expense)} more than '
              '${prev.label}.';
          tone = AppColors.warning;
          icon = Icons.trending_up_rounded;
        } else if (last.expense < prev.expense * 0.8 &&
            prev.expense > 0) {
          message = 'Expenses eased in ${last.label} — about '
              '${currency.formatCompact(prev.expense - last.expense)} less than '
              '${prev.label}.';
          tone = AppColors.success;
          icon = Icons.trending_down_rounded;
        } else {
          message = 'Money flow stayed roughly steady between ${prev.label} and '
              '${last.label}.';
        }
        break;
      case _TrendMode.savings:
        final lastNet = last.net;
        if (lastNet > 0) {
          message = 'You kept ${currency.formatCompact(lastNet)} aside in '
              '${last.label}.';
          tone = AppColors.success;
          icon = Icons.savings_rounded;
        } else if (lastNet < 0) {
          message = 'Spending exceeded income by '
              '${currency.formatCompact(-lastNet)} in ${last.label}.';
          tone = AppColors.danger;
          icon = Icons.trending_down_rounded;
        } else {
          message = 'Income and expense matched in ${last.label}.';
        }
        break;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: tone.withAlpha(28),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: tone, size: 14),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            message,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
