import 'package:flutter/material.dart';

import '../../../components/settings/settings_info_tile.dart';
import '../../../components/settings/settings_section.dart';
import '../../../components/settings/settings_subpage_scaffold.dart';
import '../../../components/settings/settings_tile.dart';
import '../../../config/design_tokens.dart';
import '../../../utils/snackbar_helper.dart';

/// Feedback channels, legal links, and the app version footer.
class SupportAndFeedbackPage extends StatelessWidget {
  const SupportAndFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSubpageScaffold(
      title: 'Support & Feedback',
      subtitle:
          'Tell us what works, what does not, and what you wish existed.',
      children: [
        SettingsSection(
          title: 'Talk to us',
          children: [
            SettingsTile(
              icon: Icons.feedback_rounded,
              title: 'Send Feedback',
              subtitle: 'Tell us what feels right or wrong',
              onTap: () => _stub(context, 'Send Feedback'),
            ),
            SettingsTile(
              icon: Icons.lightbulb_outline_rounded,
              title: 'Request a Feature',
              subtitle: 'Share what you want next',
              onTap: () => _stub(context, 'Request feature'),
            ),
            SettingsTile(
              icon: Icons.bug_report_rounded,
              title: 'Report an Issue',
              subtitle: 'Let us know what broke',
              onTap: () => _stub(context, 'Report issue'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SettingsSection(
          title: 'Legal',
          children: [
            SettingsTile(
              icon: Icons.policy_rounded,
              title: 'Privacy Policy',
              onTap: () => _stub(context, 'Privacy policy'),
            ),
            SettingsTile(
              icon: Icons.gavel_rounded,
              title: 'Terms of Service',
              onTap: () => _stub(context, 'Terms of service'),
            ),
            const SettingsInfoTile(
              icon: Icons.info_outline_rounded,
              title: 'App Version',
              valueLabel: 'v1.0.0 (1)',
            ),
          ],
        ),
      ],
    );
  }

  void _stub(BuildContext context, String label) {
    SnackbarHelper.showMessage(context, '$label is coming soon');
  }
}
