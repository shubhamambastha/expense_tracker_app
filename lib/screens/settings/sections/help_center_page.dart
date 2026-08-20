import 'package:flutter/material.dart';

import '../../../components/dialogs/confirm_reset_account_dialog.dart';
import '../../../components/settings/settings_section.dart';
import '../../../components/settings/settings_subpage_scaffold.dart';
import '../../../components/settings/settings_tile.dart';
import '../../../services/category_catalog.dart';
import '../../../services/income_category_catalog.dart';
import '../../../services/supabase_service.dart';
import '../../../utils/snackbar_helper.dart';

/// Help Center: currently just houses the destructive "Reset My Account"
/// action. Wipes transactions/accounts/categories/budgets/recurring data
/// for the signed-in user but keeps the Auth0 session and all preferences
/// (theme, currency, notification toggles, ...) untouched.
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
      subtitle: 'Answers and account tools.',
      children: [
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
      ],
    );
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
