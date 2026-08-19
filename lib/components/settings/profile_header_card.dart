import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/design_tokens.dart';

/// Hero header at the top of the Settings screen.
///
/// Shows the avatar and identity (display name + email); tapping the name
/// row opens Edit Profile. Designed to feel premium and calm — single
/// accent, soft gradient avatar, generous spacing.
class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    super.key,
    required this.initial,
    required this.displayName,
    required this.email,
    required this.onEditProfile,
  });

  /// Single capital letter for the avatar placeholder.
  final String initial;

  /// Display name (falls back to the email local-part).
  final String displayName;
  final String email;

  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surface,
            AppColors.surfaceSecondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: InkWell(
        onTap: onEditProfile,
        borderRadius: AppRadii.cardRadius,
        child: Row(
          children: [
            _Avatar(initial: initial),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headingSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: AppDurations.page)
        .slideY(
          begin: 0.04,
          end: 0,
          duration: AppDurations.page,
          curve: AppCurves.spring,
        );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withAlpha(64),
            AppColors.secondary.withAlpha(32),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withAlpha(50)),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AppTextStyles.headingSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

