import 'package:flutter/material.dart';

import '../../../../config/design_tokens.dart';

/// Shared card wrapper for detail sections.
class DetailSectionCard extends StatelessWidget {
  const DetailSectionCard({
    super.key,
    required this.child,
    this.title,
    this.accentColor,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final String? title;
  final Color? accentColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final borderColor = accentColor != null
        ? accentColor!.withAlpha(110)
        : AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: borderColor),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                title!,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Padding(
            padding: title != null
                ? padding.copyWith(top: 0)
                : padding,
            child: child,
          ),
        ],
      ),
    );
  }
}
