import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';

/// Non-interactive read-only row used for status, info copy, version,
/// etc. Renders like [SettingsTile] but without an InkWell and with an
/// optional trailing status pill or value text.
class SettingsInfoTile extends StatelessWidget {
  const SettingsInfoTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.valueLabel,
    this.statusPill,
    this.statusColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Plain text trailing (e.g. "v1.0.0+1").
  final String? valueLabel;

  /// Optional accent-tinted status pill (e.g. "Synced", "Local-first").
  final String? statusPill;

  /// Color used for the status pill. Defaults to primary if [statusPill] is set.
  final Color? statusColor;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
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
                color: AppColors.textSecondary.withAlpha(28),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                color: AppColors.textSecondary,
                size: 18,
              ),
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
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTextStyles.caption,
                      maxLines: 3,
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
    );
  }

  Widget _buildTrailing() {
    if (statusPill != null) {
      final color = statusColor ?? AppColors.primary;
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: color.withAlpha(28),
          borderRadius: AppRadii.pillRadius,
          border: Border.all(color: color.withAlpha(70)),
        ),
        child: Text(
          statusPill!,
          style: AppTextStyles.label.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      );
    }
    if (valueLabel != null) {
      return Text(
        valueLabel!,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
