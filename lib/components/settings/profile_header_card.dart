import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/design_tokens.dart';

/// Hero header at the top of the Settings screen.
///
/// Shows the avatar, identity (display name + email), a tappable currency
/// pill, the monthly spending summary, and two CTAs (Edit Profile / Manage
/// Account). Designed to feel premium and calm — single accent, soft
/// gradient avatar, generous spacing.
class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    super.key,
    required this.initial,
    required this.displayName,
    required this.email,
    required this.currencyCode,
    required this.monthSummary,
    required this.subscriptionsSummary,
    required this.onCurrencyTap,
    required this.onEditProfile,
    required this.onManageAccount,
  });

  /// Single capital letter for the avatar placeholder.
  final String initial;

  /// Display name (falls back to the email local-part).
  final String displayName;
  final String email;

  /// 3-letter currency code (e.g. "INR").
  final String currencyCode;

  /// Pre-formatted summary line (e.g. "₹28,400 spent this month").
  final String monthSummary;

  /// Optional secondary summary line (e.g. "3 subscriptions active").
  final String subscriptionsSummary;

  final VoidCallback onCurrencyTap;
  final VoidCallback onEditProfile;
  final VoidCallback onManageAccount;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              _CurrencyPill(
                code: currencyCode,
                onTap: onCurrencyTap,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SummaryRow(
            icon: Icons.trending_down_rounded,
            text: monthSummary,
            accent: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          _SummaryRow(
            icon: Icons.repeat_rounded,
            text: subscriptionsSummary,
            accent: AppColors.secondary,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEditProfile,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.border),
                    foregroundColor: AppColors.textPrimary,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit Profile'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onManageAccount,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.manage_accounts_rounded, size: 18),
                  label: const Text('Manage Account'),
                ),
              ),
            ],
          ),
        ],
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

class _CurrencyPill extends StatelessWidget {
  const _CurrencyPill({required this.code, required this.onTap});

  final String code;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.pillRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(28),
          borderRadius: AppRadii.pillRadius,
          border: Border.all(color: AppColors.primary.withAlpha(70)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              code,
              style: AppTextStyles.label.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.expand_more_rounded,
              size: 14,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.text,
    required this.accent,
  });

  final IconData icon;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withAlpha(28),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 16),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
