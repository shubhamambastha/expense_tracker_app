import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../components/dialogs/add_account_dialog.dart';
import '../../components/settings/profile_header_card.dart';
import '../../components/settings/settings_danger_section.dart';
import '../../components/settings/settings_section.dart';
import '../../components/settings/settings_tile.dart';
import '../../config/app_info.dart';
import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../services/settings_preferences.dart';
import 'sections/about_page.dart';
import 'sections/data_privacy_page.dart';
import 'sections/edit_profile_page.dart';
import 'sections/help_center_page.dart';
import 'sections/money_page.dart';
import '../../utils/profile_identity.dart';

/// Premium Settings *hub*.
///
/// Renders the profile header, grouped section cards (Money / Data &
/// Privacy / Support), and the destructive Sign Out row. Each entry pushes
/// a dedicated sub-screen so the surface area stays calm and users scroll
/// for context, not content.
///
/// All persistence still flows through [SettingsPreferences],
/// [CurrencySettings], and [CategoryCatalog] — only the shell has changed.
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.accounts,
    required this.onAddAccount,
    required this.onManageAccounts,
    required this.onOpenRecurringManager,
    required this.onOpenBudgets,
    required this.onSignOut,
    required this.onAccountReset,
    required this.onGuestDataChanged,
  });

  final List<Account> accounts;
  final OnAddAccount onAddAccount;

  /// Opens the full accounts/cards management flow (same one Home's
  /// "Manage accounts" quick link uses) so Settings doesn't maintain a
  /// second, thinner accounts screen.
  final VoidCallback onManageAccounts;

  /// Opens the full recurring-payments manager (same one Analytics'
  /// Subscriptions section uses).
  final VoidCallback onOpenRecurringManager;

  /// Leaves the Settings tab entirely and switches to the Budgets tab —
  /// Budgets is a sibling primary tab, not a Settings subpage.
  final VoidCallback onOpenBudgets;

  final VoidCallback onSignOut;

  /// Called after Data & Privacy's "Reset My Account" wipes the user's
  /// data, so the tab shell can clear its in-memory transactions/accounts.
  final VoidCallback onAccountReset;

  /// Called after a manual guest-data import from Data & Privacy's "Guest
  /// data" section so the tab shell can reload transactions/accounts.
  final VoidCallback onGuestDataChanged;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsPreferences.instance,
      builder: (context, _) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text('Settings', style: AppTextStyles.headingLarge),
              ),
              const SizedBox(height: AppSpacing.md),
              ProfileHeaderCard(
                initial: _profileInitial(),
                displayName: _displayName(),
                email: _email(),
                onEditProfile: () => _open(context, const EditProfilePage()),
              ),
              const SizedBox(height: AppSpacing.xl),
              SettingsSection(
                title: 'Money',
                children: [
                  SettingsTile(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Money',
                    subtitle: 'Currency, appearance, accounts, recurring',
                    onTap: () => _open(
                      context,
                      MoneyPage(
                        accounts: accounts,
                        onManageAccounts: onManageAccounts,
                        onOpenRecurringManager: onOpenRecurringManager,
                        onOpenBudgets: onOpenBudgets,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SettingsSection(
                title: 'Data & Privacy',
                children: [
                  SettingsTile(
                    icon: Icons.privacy_tip_rounded,
                    title: 'Data & Privacy',
                    subtitle: 'Export, backup, and account actions',
                    onTap: () => _open(
                      context,
                      DataPrivacyPage(
                        onAccountReset: onAccountReset,
                        onGuestDataChanged: onGuestDataChanged,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SettingsSection(
                title: 'Support',
                children: [
                  SettingsTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Help Center',
                    subtitle: 'Feedback, contact, offline mode',
                    onTap: () => _open(context, const HelpCenterPage()),
                  ),
                  SettingsTile(
                    icon: Icons.info_outline_rounded,
                    title: 'About',
                    onTap: () => _open(context, const AboutPage()),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              SettingsDangerSection(onLogout: onSignOut),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Text(
                  'Version ${AppInfo.version} (${AppInfo.buildNumber})',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: AppDurations.page).slideY(
          begin: 0.02,
          end: 0,
          duration: AppDurations.page,
          curve: AppCurves.spring,
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  // ---------------------------------------------------------------------------
  // Profile values
  // ---------------------------------------------------------------------------

  String _profileInitial() {
    return ProfileIdentity.initialFor(_displayName(), _email());
  }

  String _displayName() {
    final prefs = SettingsPreferences.instance;
    if (prefs.displayName.trim().isNotEmpty) return prefs.displayName.trim();
    final meta = ProfileIdentity.sessionDisplayName();
    if (meta != null) return meta;
    return ProfileIdentity.displayNameFromEmail(_email());
  }

  String _email() => ProfileIdentity.emailFor();
}
