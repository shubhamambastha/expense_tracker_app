import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../config/design_tokens.dart';

/// Visual weight for offline messaging.
enum OfflineBannerStyle {
  /// Slim top strip — "Offline Mode" with optional sync hint.
  subtle,

  /// Richer context block for dashboard areas.
  contextual,
}

/// Non-blocking offline indicator — reassures without disabling the app.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    this.title = 'Offline Mode',
    this.subtitle = 'Changes will sync automatically',
    this.style = OfflineBannerStyle.subtle,
    this.showSyncHint = true,
  });

  final String title;
  final String? subtitle;
  final OfflineBannerStyle style;
  final bool showSyncHint;

  @override
  Widget build(BuildContext context) {
    return switch (style) {
      OfflineBannerStyle.subtle => _SubtleBanner(
          title: title,
          subtitle: showSyncHint ? subtitle : null,
        ),
      OfflineBannerStyle.contextual => _ContextualBanner(
          title: title,
          subtitle: subtitle,
        ),
    };
  }
}

class _SubtleBanner extends StatelessWidget {
  const _SubtleBanner({
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warningSoft,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 16,
              color: AppColors.warning.withAlpha(220),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: AppDurations.short)
        .slideY(begin: -0.2, end: 0, duration: AppDurations.short);
  }
}

class _ContextualBanner extends StatelessWidget {
  const _ContextualBanner({
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: AppColors.warning.withAlpha(48)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(32),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.warning,
              size: 20,
            ),
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
        ],
      ),
    );
  }
}

/// Compact reassurance chip after offline save (snackbar alternative).
class OfflineSavedNotice extends StatelessWidget {
  const OfflineSavedNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: AppRadii.chipRadius,
        border: Border.all(color: AppColors.primary.withAlpha(56)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saved offline',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Will sync automatically later.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
