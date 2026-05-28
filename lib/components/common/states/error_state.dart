import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../config/design_tokens.dart';
import 'state_icon_badge.dart';

/// Layout for recoverable error surfaces.
enum ErrorStateLayout {
  /// Centered block with icon, copy, and retry.
  standard,

  /// Compact card suitable for inline sections.
  inline,

  /// Minimal banner-style row.
  banner,
}

/// Calm, recoverable error surface with human copy and retry actions.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.error_outline_rounded,
    this.primaryActionLabel = 'Retry',
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.layout = ErrorStateLayout.standard,
    this.animate = true,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final ErrorStateLayout layout;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return switch (layout) {
      ErrorStateLayout.banner => _buildBanner(),
      ErrorStateLayout.inline => _buildInline(),
      ErrorStateLayout.standard => _buildStandard(),
    };
  }

  Widget _buildStandard() {
    Widget content = Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StateIconBadge(
            icon: icon,
            tone: StateBadgeTone.danger,
            animate: animate,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: AppTextStyles.headingSmall,
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle!,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
          if (primaryActionLabel != null && onPrimaryAction != null) ...[
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: onPrimaryAction,
              child: Text(primaryActionLabel!),
            ),
          ],
          if (secondaryActionLabel != null && onSecondaryAction != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: onSecondaryAction,
              child: Text(secondaryActionLabel!),
            ),
          ],
        ],
      ),
    );

    if (animate) {
      content = content
          .animate()
          .fadeIn(duration: AppDurations.page)
          .slideY(begin: 0.05, end: 0, duration: AppDurations.page);
    }

    return Center(child: content);
  }

  Widget _buildInline() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: AppColors.danger.withAlpha(48)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.md),
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
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppTextStyles.caption),
                ],
              ],
            ),
          ),
          if (primaryActionLabel != null && onPrimaryAction != null)
            TextButton(
              onPressed: onPrimaryAction,
              child: Text(primaryActionLabel!),
            ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        border: Border(
          bottom: BorderSide(color: AppColors.danger.withAlpha(40)),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 20,
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
                if (subtitle != null)
                  Text(subtitle!, style: AppTextStyles.caption),
              ],
            ),
          ),
          if (primaryActionLabel != null && onPrimaryAction != null)
            TextButton(
              onPressed: onPrimaryAction,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              child: Text(primaryActionLabel!),
            ),
        ],
      ),
    );
  }
}
