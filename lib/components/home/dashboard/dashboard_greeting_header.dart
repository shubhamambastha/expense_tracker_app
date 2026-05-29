import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart' as intl;

import '../../../config/design_tokens.dart';
import '../../../services/settings_preferences.dart';
import '../../../utils/profile_identity.dart';

/// Top-of-screen "Good morning, Shubham" + context subtitle + avatar shortcut.
class DashboardGreetingHeader extends StatelessWidget {
  const DashboardGreetingHeader({
    super.key,
    required this.userEmail,
    required this.subtitle,
    this.onAvatarTap,
    DateTime? now,
  }) : _now = now;

  final String? userEmail;
  final String subtitle;
  final VoidCallback? onAvatarTap;
  final DateTime? _now;

  String get _greeting {
    final hour = (_now ?? DateTime.now()).hour;
    if (hour < 5) return 'Good night';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }

  String get _dateLabel {
    final n = _now ?? DateTime.now();
    return intl.DateFormat('EEEE, d MMM').format(n);
  }

  String get _displayName {
    final prefs = SettingsPreferences.instance;
    if (prefs.displayName.trim().isNotEmpty) return prefs.displayName.trim();
    final meta = ProfileIdentity.sessionDisplayName();
    if (meta != null) return meta;
    final email = userEmail ?? '';
    if (email.isEmpty) return '';
    return ProfileIdentity.displayNameFromEmail(email);
  }

  String get _avatarInitial {
    return ProfileIdentity.initialFor(
      _displayName,
      userEmail ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _displayName;
    final fullGreeting = name.isEmpty ? _greeting : '$_greeting, $name';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_dateLabel, style: AppTextStyles.label),
              const SizedBox(height: 4),
              Text(
                fullGreeting,
                style: AppTextStyles.headingMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Semantics(
          button: true,
          label: 'Open profile',
          child: InkWell(
            onTap: onAvatarTap,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withAlpha(48),
                    AppColors.secondary.withAlpha(28),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.primary.withAlpha(60)),
              ),
              alignment: Alignment.center,
              child: Text(
                _avatarInitial,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: AppDurations.reveal)
        .slideY(
          begin: -0.1,
          end: 0,
          duration: AppDurations.reveal,
          curve: AppCurves.spring,
        );
  }
}
