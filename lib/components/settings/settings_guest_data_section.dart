import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/category_catalog.dart';
import '../../services/guest_migration_service.dart';
import '../../services/guest_store.dart';
import '../../services/income_category_catalog.dart';
import '../../utils/snackbar_helper.dart';
import '../dialogs/confirm_guest_migration_dialog.dart';
import 'settings_section.dart';
import 'settings_tile.dart';

/// Shown only for a real (non-guest) signed-in user who declined the
/// migration offer at login and still has local guest data sitting unused —
/// lets them import it later, or discard it outright. Renders nothing for
/// everyone else (checked async, so this stays a small self-contained
/// widget rather than making all of [SettingsPage] async).
class SettingsGuestDataSection extends StatefulWidget {
  const SettingsGuestDataSection({super.key, this.onImported});

  /// Called after a successful import so the caller can reload its
  /// in-memory transaction/account state.
  final VoidCallback? onImported;

  @override
  State<SettingsGuestDataSection> createState() =>
      _SettingsGuestDataSectionState();
}

class _SettingsGuestDataSectionState extends State<SettingsGuestDataSection> {
  bool _busy = false;
  Future<bool>? _hasDataFuture;

  @override
  void initState() {
    super.initState();
    _refreshVisibility();
  }

  void _refreshVisibility() {
    final isRealAccount = !AuthService.instance.isGuest.value &&
        AuthService.instance.currentSession != null;
    _hasDataFuture = isRealAccount
        ? GuestStore.instance.hasMigratableData()
        : Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasDataFuture,
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        return SettingsSection(
          title: 'Guest data',
          children: [
            SettingsTile(
              icon: Icons.download_done_rounded,
              title: 'Import guest data',
              subtitle: _busy
                  ? 'Importing…'
                  : 'Bring in data left over from using guest mode',
              onTap: _busy ? null : _import,
            ),
            SettingsTile(
              icon: Icons.delete_outline_rounded,
              title: 'Discard guest data',
              subtitle: 'Erase it from this device without importing',
              destructive: true,
              onTap: _busy ? null : _discard,
            ),
          ],
        );
      },
    );
  }

  Future<void> _import() async {
    final summary = await GuestMigrationService.instance.buildSummary();
    if (!mounted) return;
    final accepted = await showGuestMigrationDialog(context, summary: summary);
    if (!accepted || !mounted) return;

    setState(() => _busy = true);
    final result = await GuestMigrationService.instance.migrate();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _refreshVisibility();
    });

    if (result.success) {
      SnackbarHelper.showSuccess(
        context,
        'Imported ${summary.transactionCount} transactions from guest mode',
      );
      widget.onImported?.call();
    } else {
      SnackbarHelper.showError(
        context,
        'Could not import your guest data — you can try again later',
      );
    }
  }

  Future<void> _discard() async {
    setState(() => _busy = true);
    await GuestStore.instance.clearEverything();
    // These singletons may still be holding guest-sourced entries in
    // memory from before sign-in — reload from the (now real) account.
    final userId = AuthService.instance.currentSession?.userId;
    if (userId != null) {
      await Future.wait([
        CategoryCatalog.instance.syncForUser(userId),
        IncomeCategoryCatalog.instance.syncForUser(userId),
      ]);
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _refreshVisibility();
    });
    SnackbarHelper.showMessage(context, 'Guest data discarded');
  }
}
