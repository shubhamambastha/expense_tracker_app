import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../config/design_tokens.dart';
import 'state_icon_badge.dart';

/// Layout density for empty states.
enum EmptyStateLayout {
  /// Centered, generous padding — full list/screen areas.
  standard,

  /// Tighter vertical rhythm — embedded in scroll views.
  compact,

  /// Horizontal row — section-level hints.
  inline,
}

/// Reusable empty state: icon, messaging hierarchy, and recovery CTAs.
///
/// Keeps copy short and actionable. Use [EmptyStatePresets] for product copy.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_rounded,
    this.iconTone = StateBadgeTone.primary,
    this.illustration,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.primaryActionIcon,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.layout = EmptyStateLayout.standard,
    this.animate = true,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final StateBadgeTone iconTone;
  final Widget? illustration;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final IconData? primaryActionIcon;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final EmptyStateLayout layout;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return switch (layout) {
      EmptyStateLayout.inline => _buildInline(context),
      EmptyStateLayout.compact => _buildCentered(context, compact: true),
      EmptyStateLayout.standard => _buildCentered(context, compact: false),
    };
  }

  Widget _buildCentered(BuildContext context, {required bool compact}) {
    final padding = compact
        ? const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xxl,
          )
        : const EdgeInsets.all(AppSpacing.xxl);

    Widget content = Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          illustration ??
              StateIconBadge(
                icon: icon,
                tone: iconTone,
                size: compact ? 56 : 72,
                iconSize: compact ? 26 : 34,
                animate: animate,
              ),
          SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
          Text(
            title,
            style: compact
                ? AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)
                : AppTextStyles.headingSmall,
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
            Text(
              subtitle!,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
          if (primaryActionLabel != null && onPrimaryAction != null) ...[
            SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),
            _buildPrimaryAction(compact: compact),
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
          .fadeIn(duration: AppDurations.page, curve: AppCurves.easeOutQuint)
          .slideY(
            begin: 0.04,
            end: 0,
            duration: AppDurations.page,
            curve: AppCurves.spring,
          );
    }

    return Center(child: content);
  }

  Widget _buildInline(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StateIconBadge(
            icon: icon,
            tone: iconTone,
            size: 40,
            iconSize: 20,
            animate: false,
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
                if (primaryActionLabel != null && onPrimaryAction != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: onPrimaryAction,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(primaryActionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryAction({required bool compact}) {
    final label = primaryActionLabel!;
    if (primaryActionIcon != null) {
      return FilledButton.icon(
        onPressed: onPrimaryAction,
        icon: Icon(primaryActionIcon, size: compact ? 18 : 20),
        label: Text(label),
        style: compact
            ? FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
              )
            : null,
      );
    }
    return FilledButton(
      onPressed: onPrimaryAction,
      child: Text(label),
    );
  }
}
