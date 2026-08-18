import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import 'widgets/analytics_section_card.dart';

/// Educational onboarding state shown when there's not enough data to power
/// the screen. Mirrors the dashboard onboarding card so users feel they're
/// inside the same product.
class AnalyticsEmptyState extends StatelessWidget {
  const AnalyticsEmptyState({
    super.key,
    required this.onAddTransaction,
  });

  final VoidCallback onAddTransaction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnalyticsSectionCard(
          useGradient: true,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withAlpha(48),
                      AppColors.secondary.withAlpha(28),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primary.withAlpha(60)),
                ),
                child: Icon(
                  Icons.insights_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Track more transactions to unlock insights',
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Analytics improve with more spending history. Once you log a few weeks, you\'ll see category breakdowns, behavioural patterns, and savings trends.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onAddTransaction,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Transaction'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _TipRow(
          icon: Icons.category_rounded,
          title: 'Categorise as you go',
          body: 'A clear category mix powers the "Where it went" chart and category insights.',
        ),
        const SizedBox(height: AppSpacing.sm),
        _TipRow(
          icon: Icons.event_repeat_rounded,
          title: 'Mark recurring expenses',
          body: 'Subscriptions and EMI light up the Subscription & Recurring section.',
        ),
        const SizedBox(height: AppSpacing.sm),
        _TipRow(
          icon: Icons.donut_small_rounded,
          title: 'Set a budget',
          body: 'Adding monthly caps lets us track guardrails in Budget Analytics.',
        ),
      ],
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return AnalyticsSectionCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(22),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(body, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
