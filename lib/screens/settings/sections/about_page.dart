import 'package:flutter/material.dart';

import '../../../components/auth/legal_notice.dart';
import '../../../components/settings/settings_info_tile.dart';
import '../../../components/settings/settings_section.dart';
import '../../../components/settings/settings_subpage_scaffold.dart';
import '../../../components/settings/settings_tile.dart';
import '../../../config/app_info.dart';
import '../../../config/design_tokens.dart';

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
              onTap: () => openLegalUrl(AppInfo.privacyUrl),
            ),
            SettingsTile(
              icon: Icons.gavel_rounded,
              title: 'Terms of Service',
              onTap: () => openLegalUrl(AppInfo.termsUrl),
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
}
