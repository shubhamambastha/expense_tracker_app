import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../config/design_tokens.dart';

/// Standardized loading indicators — avoids oversized blocking spinners.
enum AppLoadingStyle {
  /// 32px primary spinner for section-level loads.
  standard,

  /// 20px spinner for buttons and inline rows.
  inline,

  /// Subtle animated dots for lightweight status.
  dots,
}

class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({
    super.key,
    this.style = AppLoadingStyle.standard,
    this.color,
  });

  final AppLoadingStyle style;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.primary;

    return switch (style) {
      AppLoadingStyle.standard => SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: accent,
          ),
        ),
      AppLoadingStyle.inline => SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: accent,
          ),
        ),
      AppLoadingStyle.dots => _SubtleLoadingDots(color: accent),
    };
  }
}

class _SubtleLoadingDots extends StatelessWidget {
  const _SubtleLoadingDots({required this.color});

  final Color color;

  static const _dotSize = 5.0;
  static const _stagger = Duration(milliseconds: 160);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Padding(
          padding: EdgeInsets.only(left: index == 0 ? 0 : AppSpacing.sm),
          child: Container(
            width: _dotSize,
            height: _dotSize,
            decoration: BoxDecoration(
              color: color.withAlpha(180),
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .fadeIn(duration: AppDurations.micro, delay: _stagger * index)
              .then()
              .fade(
                begin: 1,
                end: 0.35,
                duration: const Duration(milliseconds: 520),
                curve: Curves.easeInOut,
              )
              .then()
              .fade(
                begin: 0.35,
                end: 1,
                duration: const Duration(milliseconds: 520),
                curve: Curves.easeInOut,
              ),
        );
      }),
    );
  }
}
