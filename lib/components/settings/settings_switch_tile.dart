import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';

/// Switch-trailing variant of [SettingsTile]. Tapping the whole row toggles
/// the switch — large touch target by design.
class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.futureReady = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  /// Swaps the switch for a small "Soon" pill so the affordance is honest
  /// when the setting isn't wired to anything yet. Mirrors
  /// [SettingsTile.futureReady].
  final bool futureReady;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primary;

    return InkWell(
      onTap: (enabled && !futureReady) ? () => onChanged(!value) : null,
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
              if (futureReady)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withAlpha(28),
                    borderRadius: AppRadii.pillRadius,
                    border: Border.all(
                      color: AppColors.secondary.withAlpha(70),
                    ),
                  ),
                  child: Text(
                    'Soon',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                )
              else
                Switch.adaptive(
                  value: value,
                  onChanged: enabled ? onChanged : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
