import 'package:flutter/material.dart';

import '../../../components/settings/settings_info_tile.dart';
import '../../../components/settings/settings_section.dart';
import '../../../components/settings/settings_subpage_scaffold.dart';
import '../../../components/settings/settings_tile.dart';
import '../../../config/app_info.dart';
import '../../../config/design_tokens.dart';
import '../../../utils/snackbar_helper.dart';

/// App version and legal links.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSubpageScaffold(
      title: 'About',
      children: [
        SettingsSection(
          title: 'Version',
          children: const [
            SettingsInfoTile(
              icon: Icons.info_outline_rounded,
              title: 'App Version',
              valueLabel: AppInfo.versionLabel,
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
            SettingsTile(
              icon: Icons.description_rounded,
              title: 'Open Source Licenses',
              onTap: () => showLicensePage(context: context),
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
