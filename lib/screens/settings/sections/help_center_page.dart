import 'package:flutter/material.dart';

import '../../../components/dialogs/confirm_reset_account_dialog.dart';
import '../../../components/settings/settings_delete_account_tile.dart';
import '../../../components/settings/settings_info_tile.dart';
import '../../../components/settings/settings_section.dart';
import '../../../components/settings/settings_subpage_scaffold.dart';
import '../../../components/settings/settings_tile.dart';
import '../../../config/design_tokens.dart';
import '../../../services/category_catalog.dart';
import '../../../services/income_category_catalog.dart';
import '../../../services/supabase_service.dart';
import '../../../utils/snackbar_helper.dart';

/// Help Center: single home for support — feedback channels, contact/rating
/// links, offline behaviour, and account tools (reset/delete). Everything
/// that used to be spread across "Contact Us", "Rate the App", and
/// "Support & Feedback" now lives here so Settings' Support section only
/// needs one entry point.
class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key, required this.onAccountReset});

  /// Called after a successful reset so the caller can clear its in-memory
  /// transaction/account state and reload.
  final VoidCallback onAccountReset;

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  bool _resetting = false;

  @override
  Widget build(BuildContext context) {
    return SettingsSubpageScaffold(
      title: 'Help Center',
      subtitle: 'Answers, feedback channels, and account tools.',
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
              icon: Icons.cloud_off_rounded,
              title: 'Offline Mode',
              subtitle: 'Reads/writes work without internet — synced later',
              statusPill: 'Local-first',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SettingsSection(
          title: 'Danger Zone',
          children: [
            SettingsTile(
              icon: Icons.restart_alt_rounded,
              title: 'Reset My Account',
              subtitle: _resetting
                  ? 'Resetting…'
                  : 'Erase transactions, accounts, categories & budgets',
              destructive: true,
              onTap: _resetting ? null : _confirmReset,
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

  Future<void> _confirmReset() async {
    final confirmed = await showConfirmResetAccountDialog(context);
    if (!confirmed || !mounted) return;

    setState(() => _resetting = true);
    try {
      final userId = SupabaseService.requireUserId();
      await SupabaseService.resetUserData();
      await Future.wait([
        CategoryCatalog.instance.syncForUser(userId),
        IncomeCategoryCatalog.instance.syncForUser(userId),
      ]);
      widget.onAccountReset();
      if (!mounted) return;
      SnackbarHelper.showSuccess(context, 'Your account has been reset');
    } catch (error) {
      if (!mounted) return;
      SnackbarHelper.showError(context, 'Could not reset your account: $error');
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }
}
