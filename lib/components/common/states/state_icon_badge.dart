import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../config/design_tokens.dart';

/// Visual tone for state icon badges.
enum StateBadgeTone {
  primary,
  secondary,
  warning,
  danger,
  neutral,
}

/// Shared icon badge used across empty, error, and offline states.
class StateIconBadge extends StatelessWidget {
  const StateIconBadge({
    super.key,
    required this.icon,
    this.tone = StateBadgeTone.primary,
    this.size = 72,
    this.iconSize = 34,
    this.animate = true,
  });

  final IconData icon;
  final StateBadgeTone tone;
  final double size;
  final double iconSize;
  final bool animate;

  Color get _accent {
    switch (tone) {
      case StateBadgeTone.primary:
        return AppColors.primary;
      case StateBadgeTone.secondary:
        return AppColors.secondary;
      case StateBadgeTone.warning:
        return AppColors.warning;
      case StateBadgeTone.danger:
        return AppColors.danger;
      case StateBadgeTone.neutral:
        return AppColors.textSecondary;
    }
  }

  Color get _background {
    switch (tone) {
      case StateBadgeTone.primary:
        return AppColors.primarySoft;
      case StateBadgeTone.secondary:
        return AppColors.secondarySoft;
      case StateBadgeTone.warning:
        return AppColors.warningSoft;
      case StateBadgeTone.danger:
        return AppColors.dangerSoft;
      case StateBadgeTone.neutral:
        return AppColors.surfaceSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: _accent.withAlpha(56)),
      ),
      child: Icon(icon, size: iconSize, color: _accent),
    );

    if (!animate) return badge;

    return badge
        .animate()
        .fadeIn(duration: AppDurations.page, curve: AppCurves.easeOutQuint)
        .scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1, 1),
          duration: AppDurations.page,
          curve: AppCurves.spring,
        );
  }
}
