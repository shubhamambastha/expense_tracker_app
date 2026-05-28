import 'package:flutter/material.dart';

import '../../../config/design_tokens.dart';
import 'app_loading_indicator.dart';

/// Display mode for [LoadingState].
enum LoadingStateMode {
  /// Centered spinner — section-level, non-blocking.
  indicator,

  /// Subtle animated dots.
  dots,

  /// Caller-provided skeleton or custom placeholder.
  custom,
}

/// Lightweight loading surface — prefer skeleton presets when layout matters.
///
/// For list/dashboard/analytics layouts, use [DashboardLoadingState],
/// [TransactionsLoadingState], etc. from `loading_states.dart`.
class LoadingState extends StatelessWidget {
  const LoadingState({
    super.key,
    this.mode = LoadingStateMode.indicator,
    this.label,
    this.customChild,
    this.padding = const EdgeInsets.all(AppSpacing.xxl),
  });

  final LoadingStateMode mode;
  final String? label;
  final Widget? customChild;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (mode == LoadingStateMode.custom && customChild != null) {
      return Padding(padding: padding, child: customChild);
    }

    final indicator = switch (mode) {
      LoadingStateMode.dots =>
        const AppLoadingIndicator(style: AppLoadingStyle.dots),
      LoadingStateMode.indicator ||
      LoadingStateMode.custom =>
        const AppLoadingIndicator(),
    };

    return Padding(
      padding: padding,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            indicator,
            if (label != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                label!,
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
