import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../components/dialogs/add_account_dialog.dart';
import '../../components/settings/currency_picker_sheet.dart';
import '../../components/settings/profile_header_card.dart';
import '../../components/settings/settings_danger_section.dart';
import '../../components/settings/settings_section.dart';
import '../../components/settings/settings_tile.dart';
import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/transaction.dart';
import '../../services/category_catalog.dart';
import '../../services/income_category_catalog.dart';
import '../../services/currency_settings.dart';
import '../../services/settings_preferences.dart';
import '../../services/supabase_service.dart';
import '../../utils/snackbar_helper.dart';
import 'sections/accounts_and_cards_page.dart';
import 'sections/categories_page.dart';
import 'sections/ai_assistant_page.dart';
import 'sections/app_preferences_page.dart';
import 'sections/budgets_and_spending_page.dart';
import 'sections/financial_preferences_page.dart';
import 'sections/notifications_page.dart';
import 'sections/edit_profile_page.dart';
import 'sections/support_and_feedback_page.dart';
import '../../utils/profile_identity.dart';

/// Premium Settings *hub*.
///
/// Renders the profile header, a single condensed list of section entries,
/// and the danger zone. Each entry pushes a dedicated sub-screen so the
/// surface area stays calm and users scroll for context, not content.
///
/// All persistence still flows through [SettingsPreferences],
/// [CurrencySettings], and [CategoryCatalog] — only the shell has changed.
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.accounts,
    required this.transactions,
    required this.onAddAccount,
    required this.onSignOut,
  });

  final List<Account> accounts;
  final List<Transaction> transactions;
  final OnAddAccount onAddAccount;
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
              ProfileHeaderCard(
                initial: _profileInitial(),
                displayName: _displayName(),
                email: _email(),
                currencyCode: currency.currencyCode,
                monthSummary:
                    '${currency.format(_monthSpent())} spent this month',
                subscriptionsSummary:
                    '${_recurringCount()} subscriptions active',
                onCurrencyTap: () => showCurrencyPickerSheet(context),
                onEditProfile: () => _open(
                  context,
                  EditProfilePage(accounts: accounts),
                ),
                onManageAccount: () => _stub(context, 'Manage Account'),
              ),
              const SizedBox(height: AppSpacing.lg),
              SettingsSection(
                title: 'Settings',
                children: [
                  SettingsTile(
                    icon: Icons.payments_rounded,
                    title: 'Financial Preferences',
                    subtitle:
                        'Currency, fiscal year, transaction defaults',
                    valueLabel: currency.currencyCode,
                    onTap: () => _open(
                      context,
                      FinancialPreferencesPage(accounts: accounts),
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.category_rounded,
                    title: 'Categories',
                    subtitle: 'Expense and income labels',
                    valueLabel: _categoriesSummary(),
                    onTap: () => _open(context, const CategoriesPage()),
                  ),
                  SettingsTile(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Accounts & Cards',
                    subtitle:
                        'Banks, credit cards, wallets, and cash',
                    valueLabel: _accountsSummary(),
                    onTap: () => _open(
                      context,
                      AccountsAndCardsPage(
                        accounts: accounts,
                        onAddAccount: onAddAccount,
                      ),
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.donut_small_rounded,
                    title: 'Budgets & Spending',
                    subtitle: 'Monthly cap, category budgets, alerts',
                    valueLabel: prefs.monthlySpendingLimit == null
                        ? 'No cap'
                        : currency.format(prefs.monthlySpendingLimit!),
                    onTap: () =>
                        _open(context, const BudgetsAndSpendingPage()),
                  ),
                  SettingsTile(
                    icon: Icons.notifications_rounded,
                    title: 'Notifications & Reminders',
                    subtitle:
                        'Recurring, salary, budget alerts & timing',
                    valueLabel: _notifSummary(prefs),
                    onTap: () => _open(context, const NotificationsPage()),
                  ),
                  SettingsTile(
                    icon: Icons.psychology_rounded,
                    title: 'AI Assistant',
                    subtitle:
                        'Insights, suggestions, chat history controls',
                    valueLabel:
                        prefs.aiAssistantEnabled ? 'On' : 'Off',
                    onTap: () => _open(context, const AiAssistantPage()),
                  ),
                  SettingsTile(
                    icon: Icons.tune_rounded,
                    title: 'App Preferences',
                    subtitle: 'Theme, lock, haptics, density',
                    valueLabel: prefs.themeModePref.label,
                    onTap: () =>
                        _open(context, const AppPreferencesPage()),
                  ),
                  SettingsTile(
                    icon: Icons.support_agent_rounded,
                    title: 'Support & Feedback',
                    subtitle:
                        'Feedback, data & privacy, legal, account removal',
                    onTap: () =>
                        _open(context, const SupportAndFeedbackPage()),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              SettingsDangerSection(onLogout: onSignOut),
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  void _stub(BuildContext context, String label) {
    SnackbarHelper.showMessage(context, '$label is coming soon');
  }

  // ---------------------------------------------------------------------------
  // Hub summaries (right-side value chips)
  // ---------------------------------------------------------------------------

  String _categoriesSummary() {
    final total = CategoryCatalog.instance.categories.length +
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
    final meta = ProfileIdentity.metadataDisplayName(
      SupabaseService.currentUser,
    );
    if (meta != null) return meta;
    return ProfileIdentity.displayNameFromEmail(_email());
  }

  String _email() => ProfileIdentity.emailFor(SupabaseService.currentUser);

  double _monthSpent() {
    final now = DateTime.now();
    return transactions
        .where((t) =>
            t.isExpense &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold<double>(0, (sum, t) => sum + t.amount);
  }

  int _recurringCount() =>
      transactions.where((t) => t.isRecurring).length;
}
