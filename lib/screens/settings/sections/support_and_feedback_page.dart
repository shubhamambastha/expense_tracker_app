import 'package:flutter/material.dart';

import '../../../components/settings/settings_delete_account_tile.dart';
import '../../../components/settings/settings_info_tile.dart';
import '../../../components/settings/settings_section.dart';
import '../../../components/settings/settings_subpage_scaffold.dart';
import '../../../components/settings/settings_tile.dart';
import '../../../config/design_tokens.dart';
import '../../../utils/snackbar_helper.dart';

/// Feedback channels, offline behaviour, and account deletion.
///
/// Export Data lives in Settings' Data group, Backup & Sync in Security,
/// and legal/version links in the About page — this page keeps the
/// feedback channels and the one destructive action.
class SupportAndFeedbackPage extends StatelessWidget {
  const SupportAndFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSubpageScaffold(
      title: 'Support & Feedback',
      subtitle: 'Tell us what works, what does not, and what you wish existed.',
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
          title: 'Data',
          children: const [
            SettingsInfoTile(
              icon: Icons.cloud_off_rounded,
              title: 'Offline Mode',
              subtitle: 'Reads/writes work without internet — synced later',
              statusPill: 'Local-first',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        SettingsDeleteAccountSection(
          onDeleteConfirmed: () => _stub(context, 'Account deletion'),
        ),
      ],
    );
  }

  void _stub(BuildContext context, String label) {
    SnackbarHelper.showMessage(context, '$label is coming soon');
  }
}
