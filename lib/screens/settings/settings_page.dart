import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../components/dialogs/add_account_dialog.dart';
import '../../components/settings/currency_picker_sheet.dart';
import '../../components/settings/profile_header_card.dart';
import '../../components/settings/settings_danger_section.dart';
import '../../components/settings/settings_info_tile.dart';
import '../../components/settings/settings_section.dart';
import '../../components/settings/settings_tile.dart';
import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../services/category_catalog.dart';
import '../../services/income_category_catalog.dart';
import '../../services/currency_settings.dart';
import '../../services/settings_preferences.dart';
import '../../utils/snackbar_helper.dart';
import 'sections/about_page.dart';
import 'sections/appearance_page.dart';
import 'sections/categories_page.dart';
import 'sections/ai_assistant_page.dart';
import 'sections/app_preferences_page.dart';
import 'sections/financial_preferences_page.dart';
import 'sections/notifications_page.dart';
import 'sections/edit_profile_page.dart';
import 'sections/security_page.dart';
import 'sections/support_and_feedback_page.dart';
import '../../utils/profile_identity.dart';

/// Premium Settings *hub*.
///
/// Renders the profile header, grouped section cards (Preferences / Data /
/// Security / Support / About), and the destructive Sign Out row. Each
/// entry pushes a dedicated sub-screen so the surface area stays calm and
/// users scroll for context, not content.
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
    required this.onSignOut,
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

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        CurrencySettings.instance,
        SettingsPreferences.instance,
        CategoryCatalog.instance,
        IncomeCategoryCatalog.instance,
      ]),
      builder: (context, _) {
        final currency = CurrencySettings.instance;
        final prefs = SettingsPreferences.instance;

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
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Text('Settings', style: AppTextStyles.headingLarge),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ProfileHeaderCard(
                    initial: _profileInitial(),
                    displayName: _displayName(),
                    email: _email(),
                    onEditProfile: () =>
                        _open(context, const EditProfilePage()),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SettingsSection(
                    title: 'Preferences',
                    children: [
                      SettingsTile(
                        icon: Icons.attach_money_rounded,
                        title: 'Currency',
                        valueLabel: currency.currencyCode,
                        onTap: () => showCurrencyPickerSheet(context),
                      ),
                      SettingsTile(
                        icon: Icons.dark_mode_rounded,
                        title: 'Appearance',
                        valueLabel: prefs.themeMode == ThemeMode.light
                            ? 'Light'
                            : 'Dark',
                        onTap: () => _open(context, const AppearancePage()),
                      ),
                      SettingsTile(
                        icon: Icons.notifications_rounded,
                        title: 'Notifications',
                        valueLabel: _notifSummary(prefs),
                        onTap: () => _open(context, const NotificationsPage()),
                      ),
                      SettingsTile(
                        icon: Icons.payments_rounded,
                        title: 'Financial Preferences',
                        subtitle: 'Transaction defaults, multi-currency',
                        onTap: () => _open(
                          context,
                          FinancialPreferencesPage(accounts: accounts),
                        ),
                      ),
                      SettingsTile(
                        icon: Icons.psychology_rounded,
                        title: 'AI Assistant',
                        valueLabel: prefs.aiAssistantEnabled ? 'On' : 'Off',
                        onTap: () => _open(context, const AiAssistantPage()),
                      ),
                      SettingsTile(
                        icon: Icons.tune_rounded,
                        title: 'App Preferences',
                        subtitle: 'Haptics, density',
                        onTap: () => _open(context, const AppPreferencesPage()),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SettingsSection(
                    title: 'Data',
                    children: [
                      SettingsTile(
                        icon: Icons.account_balance_wallet_rounded,
                        title: 'Accounts & Cards',
                        valueLabel: _accountsSummary(),
                        onTap: onManageAccounts,
                      ),
                      SettingsTile(
                        icon: Icons.category_rounded,
                        title: 'Categories',
                        valueLabel: _categoriesSummary(),
                        onTap: () => _open(context, const CategoriesPage()),
                      ),
                      SettingsTile(
                        icon: Icons.autorenew_rounded,
                        title: 'Recurring Payments',
                        onTap: onOpenRecurringManager,
                      ),
                      SettingsTile(
                        icon: Icons.file_download_rounded,
                        title: 'Export Data',
                        onTap: () => _stub(context, 'Export data'),
                      ),
                      const SettingsInfoTile(
                        icon: Icons.cloud_done_rounded,
                        title: 'Sync Status',
                        subtitle: 'All changes synced',
                        statusPill: 'Synced',
                      ),
                      const SettingsInfoTile(
                        icon: Icons.offline_bolt_rounded,
                        title: 'Offline Data',
                        subtitle:
                            'Reads and writes work offline — synced when '
                            'you reconnect',
                        statusPill: 'Local-first',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SettingsSection(
                    title: 'Security',
                    children: [
                      SettingsTile(
                        icon: Icons.fingerprint_rounded,
                        title: 'Security',
                        subtitle: 'App lock and session',
                        valueLabel: prefs.appLockEnabled ? 'On' : 'Off',
                        onTap: () => _open(context, const SecurityPage()),
                      ),
                      SettingsTile(
                        icon: Icons.cloud_done_rounded,
                        title: 'Backup & Sync',
                        futureReady: true,
                        onTap: () => _stub(context, 'Backup & Sync'),
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
                        onTap: () => _stub(context, 'Help Center'),
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
                      SettingsTile(
                        icon: Icons.support_agent_rounded,
                        title: 'Support & Feedback',
                        subtitle: 'Feedback, offline mode, delete account',
                        onTap: () =>
                            _open(context, const SupportAndFeedbackPage()),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SettingsSection(
                    title: 'About',
                    children: [
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
                      'Version 1.0.0 (1)',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: AppDurations.page)
            .slideY(
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

  void _stub(BuildContext context, String label) {
    SnackbarHelper.showMessage(context, '$label is coming soon');
  }

  // ---------------------------------------------------------------------------
  // Hub summaries (right-side value chips)
  // ---------------------------------------------------------------------------

  String _categoriesSummary() {
    final total =
        CategoryCatalog.instance.categories.length +
        IncomeCategoryCatalog.instance.categories.length;
    if (total == 0) return 'None yet';
    if (total == 1) return '1 label';
    return '$total labels';
  }

  String _accountsSummary() {
    final total = accounts.length;
    if (total == 0) return 'None yet';
    if (total == 1) return '1 linked';
    return '$total linked';
  }

  String _notifSummary(SettingsPreferences prefs) {
    final count = [
      prefs.notifRecurringEnabled,
      prefs.notifSalaryEnabled,
      prefs.notifBudgetEnabled,
      prefs.notifInsightsEnabled,
    ].where((v) => v).length;
    if (count == 0) return 'All off';
    if (count == 4) return 'All on';
    return '$count of 4';
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
