import 'package:flutter/material.dart';

import '../../../config/design_tokens.dart';
import 'app_loading_indicator.dart';
import 'shimmer_box.dart';
import 'skeleton_card.dart';
import 'skeleton_transaction_row.dart';
import 'state_content_transition.dart';

/// Non-blocking dashboard skeleton — preserves layout, no fullscreen spinner.
class DashboardLoadingState extends StatelessWidget {
  const DashboardLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonHeroCard(),
          SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: SkeletonMetricTile()),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: SkeletonMetricTile()),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          SkeletonChartPlaceholder(height: 140),
          SizedBox(height: AppSpacing.lg),
          SkeletonBlock(width: 120, height: 12),
          SizedBox(height: AppSpacing.md),
          SkeletonTransactionList(itemCount: 4),
        ],
      ),
    );
  }
}

/// Progressive transaction list loading with skeleton rows.
class TransactionsLoadingState extends StatelessWidget {
  const TransactionsLoadingState({
    super.key,
    this.itemCount = 8,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SkeletonTransactionList(itemCount: itemCount);
  }
}

/// Analytics screen loading — metric tiles + chart placeholders.
class AnalyticsLoadingState extends StatelessWidget {
  const AnalyticsLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: SkeletonMetricTile()),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: SkeletonMetricTile()),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: SkeletonMetricTile()),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: SkeletonMetricTile()),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          SkeletonChartPlaceholder(height: 200),
          SizedBox(height: AppSpacing.lg),
          SkeletonChartPlaceholder(height: 160),
          SizedBox(height: AppSpacing.lg),
          Center(child: AppLoadingIndicator(style: AppLoadingStyle.dots)),
        ],
      ),
    );
  }
}

/// Detail screen partial skeleton with fade-in ready wrapper.
class DetailLoadingState extends StatelessWidget {
  const DetailLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: SkeletonBlock(width: 120, height: 36, borderRadius: 10),
          ),
          SizedBox(height: AppSpacing.xl),
          SkeletonCard(height: 100, showHeader: false),
          SizedBox(height: AppSpacing.md),
          SkeletonCard(height: 72, showHeader: true, showFooter: false),
          SizedBox(height: AppSpacing.md),
          SkeletonCard(height: 120, showHeader: true),
        ],
      ),
    );
  }
}

/// Subtle inline search loading — does not block the screen.
class SearchLoadingState extends StatelessWidget {
  const SearchLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Center(
        child: AppLoadingIndicator(style: AppLoadingStyle.dots),
      ),
    );
  }
}

/// Wraps loaded content with skeleton → content fade transition.
class ProgressiveLoadWrapper extends StatelessWidget {
  const ProgressiveLoadWrapper({
    super.key,
    required this.isLoading,
    required this.content,
    required this.skeleton,
  });

  final bool isLoading;
  final Widget content;
  final Widget skeleton;

  @override
  Widget build(BuildContext context) {
    return StateContentTransition(
      isReady: !isLoading,
      placeholder: skeleton,
      child: content,
    );
  }
}
