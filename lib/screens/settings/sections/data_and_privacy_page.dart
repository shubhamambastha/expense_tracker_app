import 'package:flutter/material.dart';

import '../../../components/settings/settings_info_tile.dart';
import '../../../components/settings/settings_picker_helpers.dart';
import '../../../components/settings/settings_section.dart';
import '../../../components/settings/settings_subpage_scaffold.dart';
import '../../../components/settings/settings_tile.dart';
import '../../../config/design_tokens.dart';
import '../../../services/settings_preferences.dart';
import '../../../utils/snackbar_helper.dart';

/// Export, backup status, and the destructive "delete account" entry point.
class DataAndPrivacyPage extends StatelessWidget {
  const DataAndPrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSubpageScaffold(
      title: 'Data & Privacy',
      subtitle:
          'Export your data, check sync status, and manage account-level '
          'destructive actions.',
      children: [
        SettingsSection(
          title: 'Data',
          children: [
            SettingsTile(
              icon: Icons.file_download_rounded,
              title: 'Export Data',
              subtitle: 'Download transactions as CSV or JSON',
              onTap: () => _pickExportFormat(context),
            ),
            const SettingsInfoTile(
              icon: Icons.cloud_done_rounded,
              title: 'Backup & Sync',
              subtitle: 'Last sync: just now',
              statusPill: 'Synced',
            ),
            const SettingsInfoTile(
              icon: Icons.cloud_off_rounded,
              title: 'Offline Mode',
              subtitle:
                  'Reads/writes work without internet — synced later',
              statusPill: 'Local-first',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SettingsSection(
          title: 'Danger zone',
          children: [
            SettingsTile(
              icon: Icons.delete_forever_rounded,
              title: 'Delete Account',
              subtitle: 'Permanently remove your account and data',
              destructive: true,
              onTap: () => _stub(context, 'Account deletion'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickExportFormat(BuildContext context) async {
    final picked = await selectFromList<ExportFormat>(
      context: context,
      title: 'Export data',
      subtitle: 'Choose the file format to download.',
      current: null,
      options: ExportFormat.values,
      labelFor: (v) => v.label,
    );
    if (picked != null && context.mounted) {
      _stub(context, '${picked.label} export');
    }
  }

  void _stub(BuildContext context, String label) {
    SnackbarHelper.showMessage(context, '$label is coming soon');
  }
}
