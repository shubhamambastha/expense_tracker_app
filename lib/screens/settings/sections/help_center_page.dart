import 'package:flutter/material.dart';

import '../../../components/settings/settings_info_tile.dart';
import '../../../components/settings/settings_section.dart';
import '../../../components/settings/settings_subpage_scaffold.dart';
import '../../../components/settings/settings_tile.dart';
import '../../../config/design_tokens.dart';
import '../../../utils/snackbar_helper.dart';

/// Help Center: single home for support — feedback channels, contact/rating
/// links, and offline behaviour. Account tools (reset/delete) live in Data
/// & Privacy instead — this page only needs one entry point for support.
class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSubpageScaffold(
      title: 'Help Center',
      subtitle: 'Answers and feedback channels.',
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
            SettingsTile(
              icon: Icons.mail_outline_rounded,
              title: 'Contact Us',
              onTap: () => _stub(context, 'Contact Us'),
            ),
            SettingsTile(
              icon: Icons.star_outline_rounded,
              title: 'Rate the App',
              onTap: () => _stub(context, 'Rate the App'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SettingsSection(
          title: 'Data',
          children: const [
            SettingsInfoTile(
              icon: Icons.wifi_rounded,
              title: 'Signed-in Accounts',
              subtitle:
                  'Every read and write goes straight to your account — an '
                  'internet connection is required. Guest mode is the only '
                  'offline option; it stores everything on this device.',
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
