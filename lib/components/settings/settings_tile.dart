import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';

/// Generic settings row.
///
/// - Tap-able by default (renders chevron when no [trailing] is provided).
/// - [valueLabel] renders just before the chevron for "current selection"
///   style rows (e.g. "INR", "Apr–Mar").
/// - [destructive] tints the icon container + title red.
/// - [futureReady] swaps the chevron for a small "Soon" pill so the
///   affordance is honest when the action is not yet wired.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.valueLabel,
    this.trailing,
    this.onTap,
    this.destructive = false,
    this.futureReady = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? valueLabel;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;
  final bool futureReady;

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? AppColors.danger : AppColors.primary;
    final titleColor =
        destructive ? AppColors.danger : AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withAlpha(28),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTextStyles.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildTrailing(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrailing() {
    if (trailing != null) return trailing!;

    if (futureReady) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: AppColors.secondary.withAlpha(28),
          borderRadius: AppRadii.pillRadius,
          border: Border.all(color: AppColors.secondary.withAlpha(70)),
        ),
        child: Text(
          'Soon',
          style: AppTextStyles.label.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      );
    }

    if (onTap == null) {
      return const SizedBox.shrink();
    }

    if (valueLabel != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              valueLabel!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ],
      );
    }

    return const Icon(
      Icons.chevron_right_rounded,
      color: AppColors.textSecondary,
      size: 20,
    );
  }
}
