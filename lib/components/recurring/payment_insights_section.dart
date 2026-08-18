import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../services/currency_settings.dart';
import '../../utils/recurring_management.dart';
import '../analytics/widgets/analytics_section_card.dart';
import '../home/dashboard/dashboard_section_header.dart';

/// Conversational, low-density financial-awareness lines.
///
/// Intentionally keeps copy short and avoids any number-heavy comparisons —
/// the spec calls for "lightweight" insights. AI-driven extensions plug in by
/// extending [_buildInsights] without changing the surrounding layout.
class PaymentInsightsSection extends StatelessWidget {
  const PaymentInsightsSection({
    super.key,
    required this.snapshot,
    this.monthlyIncome,
  });

  final RecurringManagementSnapshot snapshot;

  /// Optional monthly income hint — when present, surfaces an "EMIs consume
  /// X% of monthly income" line. Pass null to hide that line.
  final double? monthlyIncome;

  @override
  Widget build(BuildContext context) {
    final insights = _buildInsights();
    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionHeader(
          title: 'Payment Insights',
          subtitle: 'A calmer view of your recurring spend.',
        ),
        const SizedBox(height: AppSpacing.md),
        AnalyticsSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < insights.length; i++) ...[
                _InsightLine(insight: insights[i]),
                if (i != insights.length - 1) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<_Insight> _buildInsights() {
    final currency = CurrencySettings.instance;
    final out = <_Insight>[];

    if (snapshot.subscriptionsMonthly > 0) {
      out.add(
        _Insight(
          icon: Icons.subscriptions_rounded,
          tone: AppColors.secondary,
          message:
              'Subscriptions cost about ${currency.formatCompact(snapshot.subscriptionsMonthly)} per month.',
        ),
      );
    }

    if (monthlyIncome != null &&
        monthlyIncome! > 0 &&
        snapshot.emisMonthly > 0) {
      final share = (snapshot.emisMonthly / monthlyIncome!) * 100;
      final pct = share.clamp(0, 999).toStringAsFixed(0);
      out.add(
        _Insight(
          icon: Icons.receipt_long_rounded,
          tone: AppColors.warning,
          message: 'EMIs consume around $pct% of your monthly income.',
        ),
      );
    } else if (snapshot.emisMonthly > 0) {
      out.add(
        _Insight(
          icon: Icons.receipt_long_rounded,
          tone: AppColors.warning,
          message:
              'EMIs add up to ${currency.formatCompact(snapshot.emisMonthly)} every month.',
        ),
      );
    }

    final dueThisWeek = snapshot.upcoming
        .where((u) => u.daysUntil <= 7)
        .length;
    if (dueThisWeek > 0) {
      out.add(
        _Insight(
          icon: Icons.schedule_rounded,
          tone: AppColors.primary,
          message: dueThisWeek == 1
              ? '1 payment is due this week.'
              : '$dueThisWeek payments are due this week.',
        ),
      );
    }

    if (out.isEmpty && snapshot.totalMonthly > 0) {
      out.add(
        _Insight(
          icon: Icons.event_repeat_rounded,
          tone: AppColors.primary,
          message:
              'About ${currency.formatCompact(snapshot.totalMonthly)} leaves '
              'your accounts on autopilot each month.',
        ),
      );
    }

    return out;
  }
}

class _Insight {
  const _Insight({
    required this.icon,
    required this.tone,
    required this.message,
  });

  final IconData icon;
  final Color tone;
  final String message;
}

class _InsightLine extends StatelessWidget {
  const _InsightLine({required this.insight});

  final _Insight insight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: insight.tone.withAlpha(28),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(insight.icon, size: 14, color: insight.tone),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            insight.message,
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
