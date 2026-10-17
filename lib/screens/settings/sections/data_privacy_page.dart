import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../components/common/states/states.dart';
import '../../../components/dialogs/confirm_reset_account_dialog.dart';
import '../../../components/settings/settings_delete_account_tile.dart';
import '../../../components/settings/settings_guest_data_section.dart';
import '../../../components/settings/settings_section.dart';
import '../../../components/settings/settings_subpage_scaffold.dart';
import '../../../components/settings/settings_tile.dart';
import '../../../config/design_tokens.dart';
import '../../../models/account.dart';
import '../../../models/category_budget.dart';
import '../../../models/transaction.dart';
import '../../../services/auth_service.dart';
import '../../../services/category_catalog.dart';
import '../../../services/income_category_catalog.dart';
import '../../../services/api_service.dart';
import '../../../utils/data_export.dart';
import '../../../utils/snackbar_helper.dart';

/// Export, backup, guest-data migration, and the destructive account
/// actions (reset/delete) — everything about what happens to your data.
class DataPrivacyPage extends StatefulWidget {
  const DataPrivacyPage({
    super.key,
    required this.onAccountReset,
    required this.onGuestDataChanged,
    required this.onAccountDeleted,
  });

  /// Called after "Reset My Account" wipes the user's data, so the tab
  /// shell can clear its in-memory transactions/accounts.
  final VoidCallback onAccountReset;

  /// Called after a manual guest-data import so the tab shell can reload
  /// transactions/accounts.
  final VoidCallback onGuestDataChanged;

  /// Called after the account is deleted, once every route above the tab
  /// shell is popped — signs out and returns to login.
  final VoidCallback onAccountDeleted;

  @override
  State<DataPrivacyPage> createState() => _DataPrivacyPageState();
}

class _DataPrivacyPageState extends State<DataPrivacyPage> {
  bool _resetting = false;
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final isGuest = AuthService.instance.isGuest.value;

    return SettingsSubpageScaffold(
      title: 'Data & Privacy',
      children: [
        SettingsSection(
          title: 'Export',
          children: [
            SettingsTile(
              icon: Icons.file_download_rounded,
              title: 'Export Data',
              subtitle: isGuest ? null : 'Emailed to you as CSV files',
              onTap: () =>
                  isGuest ? _exportData(context) : _emailExport(context),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SettingsSection(
          title: 'Backup',
          children: [
            SettingsTile(
              icon: Icons.cloud_done_rounded,
              title: 'Backup & Sync',
              futureReady: true,
              onTap: () => SnackbarHelper.showMessage(
                context,
                'Backup & Sync is coming soon',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SettingsGuestDataSection(onImported: widget.onGuestDataChanged),
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
        if (!isGuest) ...[
          const SizedBox(height: AppSpacing.md),
          SettingsDeleteAccountSection(
            isDeleting: _deleting,
            onDeleteConfirmed: _deleteAccount,
          ),
        ],
      ],
    );
  }

  Future<void> _deleteAccount() async {
    setState(() => _deleting = true);
    try {
      await ApiService.deleteUserAccount();
    } catch (error) {
      if (!mounted) return;
      SnackbarHelper.showError(
        context,
        error is ApiException
            ? 'Could not delete your account: ${error.message}'
            : 'Could not delete your account. Please try again.',
      );
      setState(() => _deleting = false);
      return;
    }
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    widget.onAccountDeleted();
  }

  Future<void> _confirmReset() async {
    final confirmed = await showConfirmResetAccountDialog(context);
    if (!confirmed || !mounted) return;

    setState(() => _resetting = true);
    try {
      // A guest has no session, and resetUserData()/syncForUser() are
      // already guest-branched, so any non-empty placeholder is fine here
      // (see ApiService._isGuest).
      final userId = AuthService.instance.currentSession?.userId ?? 'guest';
      await ApiService.resetUserData();
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

  /// Signed-in export: the API builds the CSVs and emails them to the
  /// address on the login, so nothing is written to the device.
  Future<void> _emailExport(BuildContext context) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: AppLoadingIndicator()),
    );
    try {
      final email = await ApiService.emailDataExport();
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      SnackbarHelper.showSuccess(context, 'Your data is on its way to $email');
    } catch (error) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      SnackbarHelper.showError(
        context,
        error is ApiException && error.statusCode < 500
            ? 'Could not email your data: ${error.message}'
            : 'Could not email your data. Please try again.',
      );
    }
  }

  /// Guest export (data lives on-device): fetches everything fresh (not any
  /// in-memory list, which may be stale/paginated), serializes it to CSV,
  /// and hands it to the OS share sheet.
  Future<void> _exportData(BuildContext context) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: AppLoadingIndicator()),
    );

    try {
      final results = await Future.wait([
        ApiService.fetchTransactions(),
        ApiService.fetchAccounts(includeArchived: true),
        ApiService.fetchCategoryBudgets(),
      ]);
      final transactions = results[0] as List<Transaction>;
      final exportAccounts = results[1] as List<Account>;
      final budgets = results[2] as List<CategoryBudget>;

      final tempDir = Directory.systemTemp;
      final files = <XFile>[
        await _writeCsv(
          tempDir,
          'transactions.csv',
          transactionsToCsv(transactions),
        ),
        await _writeCsv(tempDir, 'accounts.csv', accountsToCsv(exportAccounts)),
        await _writeCsv(tempDir, 'budgets.csv', categoryBudgetsToCsv(budgets)),
      ];

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await SharePlus.instance.share(
        ShareParams(files: files, subject: 'My expense data export'),
      );
    } catch (_) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      SnackbarHelper.showError(
        context,
        'Could not export your data. Please try again.',
      );
    }
  }

  Future<XFile> _writeCsv(Directory dir, String name, String csv) async {
    final file = await File('${dir.path}/$name').writeAsString(csv);
    return XFile(file.path, mimeType: 'text/csv');
  }
}
