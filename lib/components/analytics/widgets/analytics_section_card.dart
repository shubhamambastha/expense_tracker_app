import 'package:flutter/material.dart';

import '../../../config/design_tokens.dart';

/// A bordered surface shared by every analytics card.
///
/// Adopts the same border+shadow combo the dashboard uses (`AppColors.surface`,
/// subtle border, soft elevation) so the screen feels like a single coherent
/// system, never a foreign visual region.
class AnalyticsSectionCard extends StatelessWidget {
  const AnalyticsSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.xl,
      AppSpacing.lg,
      AppSpacing.xl,
      AppSpacing.lg,
    ),
    this.useGradient = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// When true, swaps the flat fill for a soft `surface → surfaceSecondary`
  /// gradient — reserved for hero-level cards (Spending Overview).
  final bool useGradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: useGradient
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.surface, AppColors.surfaceSecondary],
              )
            : null,
        color: useGradient ? null : AppColors.surface,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      padding: padding,
      child: child,
    );
  }
}
