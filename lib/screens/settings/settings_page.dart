import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../components/profile/profile_manage_card.dart';
import '../../components/settings/currency_picker_sheet.dart';
import '../../components/settings/profile_header_card.dart';
import '../../components/settings/settings_danger_section.dart';
import '../../components/settings/settings_info_tile.dart';
import '../../components/settings/settings_section.dart';
import '../../components/settings/settings_switch_tile.dart';
import '../../components/settings/settings_tile.dart';
import '../../config/design_tokens.dart';
import '../../models/account.dart';
import '../../models/expense.dart';
import '../../services/category_catalog.dart';
import '../../services/currency_settings.dart';
import '../../services/settings_preferences.dart';
import '../../services/supabase_service.dart';
import '../../utils/snackbar_helper.dart';

/// Premium Settings screen.
///
/// One scrollable column of grouped sections. Toggles & pickers persist
/// through [SettingsPreferences]; currency, categories, and accounts route
/// through their existing services. All not-yet-implemented actions surface
/// a friendly Snackbar via [SnackbarHelper] so the affordance is honest.
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.accounts,
    required this.expenses,
    required this.onAddAccount,
    required this.onSignOut,
  });

  final List<Account> accounts;
  final List<Expense> expenses;
  final VoidCallback onAddAccount;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        CurrencySettings.instance,
        SettingsPreferences.instance,
        CategoryCatalog.instance,
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
                onEditProfile: () => _stub(context, 'Edit Profile'),
                onManageAccount: () => _stub(context, 'Manage Account'),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildFinancialPreferences(context, prefs, currency),
              const SizedBox(height: AppSpacing.lg),
              _buildAccountsAndCards(context),
              const SizedBox(height: AppSpacing.lg),
              _buildBudgetsAndSpending(context, prefs, currency),
              const SizedBox(height: AppSpacing.lg),
              _buildNotifications(context, prefs),
              const SizedBox(height: AppSpacing.lg),
              _buildAiAssistant(context, prefs),
              const SizedBox(height: AppSpacing.lg),
              _buildDataAndPrivacy(context),
              const SizedBox(height: AppSpacing.lg),
              _buildAppPreferences(context, prefs),
              const SizedBox(height: AppSpacing.lg),
              _buildSupportAndFeedback(context),
              const SizedBox(height: AppSpacing.xl),
              SettingsDangerSection(
                onLogout: onSignOut,
                onDeleteAccount: () => _stub(context, 'Account deletion'),
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
  // Section: 2. Financial Preferences
  // ---------------------------------------------------------------------------

  Widget _buildFinancialPreferences(
    BuildContext context,
    SettingsPreferences prefs,
    CurrencySettings currency,
  ) {
    return SettingsSection(
      title: 'Financial Preferences',
      children: [
        SettingsTile(
          icon: Icons.payments_rounded,
          title: 'Base Currency',
          subtitle: 'Used for analytics & summaries',
          valueLabel: currency.currencyCode,
          onTap: () => showCurrencyPickerSheet(context),
        ),
        SettingsSwitchTile(
          icon: Icons.swap_horiz_rounded,
          title: 'Multi-Currency',
          subtitle: 'Track foreign currencies on individual entries',
          value: prefs.multiCurrencyEnabled,
          onChanged: prefs.setMultiCurrencyEnabled,
        ),
        SettingsTile(
          icon: Icons.calendar_view_month_rounded,
          title: 'Financial Year',
          subtitle: 'Boundary for analytics & budgets',
          valueLabel: prefs.financialYear.short,
          onTap: () => _pickFinancialYear(context, prefs),
        ),
        SettingsTile(
          icon: Icons.outbox_rounded,
          title: 'Default Expense Account',
          subtitle: 'Preselected for new expenses',
          valueLabel:
              _accountNameForId(prefs.defaultExpenseAccountId) ?? 'Auto',
          onTap: () => _pickDefaultAccount(
            context,
            currentId: prefs.defaultExpenseAccountId,
            onPicked: prefs.setDefaultExpenseAccountId,
            title: 'Default expense account',
          ),
        ),
        SettingsTile(
          icon: Icons.inbox_rounded,
          title: 'Default Income Account',
          subtitle: 'Preselected for new income',
          valueLabel:
              _accountNameForId(prefs.defaultIncomeAccountId) ?? 'Auto',
          onTap: () => _pickDefaultAccount(
            context,
            currentId: prefs.defaultIncomeAccountId,
            onPicked: prefs.setDefaultIncomeAccountId,
            title: 'Default income account',
          ),
        ),
        SettingsTile(
          icon: Icons.compare_arrows_rounded,
          title: 'Default Transaction Type',
          subtitle: 'Starting tab on Add Transaction',
          valueLabel: prefs.defaultTransactionType.label,
          onTap: () => _pickDefaultTransactionType(context, prefs),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Section: 3. Accounts & Cards
  // ---------------------------------------------------------------------------

  Widget _buildAccountsAndCards(BuildContext context) {
    final bankAccounts =
        accounts.where((a) => a.type == AccountType.bank).toList();
    final creditCards =
        accounts.where((a) => a.type == AccountType.creditCard).toList();
    final cashAccounts =
        accounts.where((a) => a.type == AccountType.cash).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xs,
            0,
            AppSpacing.xs,
            AppSpacing.sm,
          ),
          child: Text(
            'ACCOUNTS & CARDS',
            style: AppTextStyles.label.copyWith(letterSpacing: 0.8),
          ),
        ),
        ProfileManageCard(
          title: 'Bank Accounts',
          subtitle: _countLabel(bankAccounts.length, 'account', 'accounts'),
          seeAllLabel: 'See all',
          addLabel: 'Add Account',
          onSeeAll: () => _openAccountsSheet(
            context,
            title: 'Bank accounts',
            list: bankAccounts,
            emptyHint: 'No bank accounts yet. Tap Add Account to create one.',
          ),
          onAdd: onAddAccount,
        ),
        const SizedBox(height: AppSpacing.md),
        ProfileManageCard(
          title: 'Credit Cards',
          subtitle: _countLabel(creditCards.length, 'card', 'cards'),
          seeAllLabel: 'See all',
          addLabel: 'Add Card',
          onSeeAll: () => _openAccountsSheet(
            context,
            title: 'Credit cards',
            list: creditCards,
            emptyHint:
                'No credit cards yet. Tap Add Card to start tracking one.',
            extraTiles: [
              SettingsTile(
                icon: Icons.calendar_month_rounded,
                title: 'Manage EMI',
                subtitle: 'Split purchases into EMIs',
                futureReady: true,
                onTap: () => _stub(context, 'EMI manager'),
              ),
              SettingsTile(
                icon: Icons.event_repeat_rounded,
                title: 'Edit billing cycle',
                subtitle: 'Statement start & due day',
                futureReady: true,
                onTap: () => _stub(context, 'Billing cycle'),
              ),
            ],
          ),
          onAdd: onAddAccount,
        ),
        const SizedBox(height: AppSpacing.md),
        ProfileManageCard(
          title: 'Wallets & UPI',
          subtitle: 'GPay, PhonePe, Paytm',
          seeAllLabel: 'See all',
          addLabel: 'Link',
          onSeeAll: () => _stub(context, 'Wallets & UPI'),
          onAdd: () => _stub(context, 'Link wallet'),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.cardRadius,
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          clipBehavior: Clip.antiAlias,
          child: SettingsTile(
            icon: Icons.savings_rounded,
            title: 'Cash Wallet',
            subtitle: cashAccounts.isEmpty
                ? 'No cash wallet yet'
                : _countLabel(cashAccounts.length, 'wallet', 'wallets'),
            valueLabel: cashAccounts.isEmpty ? 'Add' : 'Manage',
            onTap: cashAccounts.isEmpty
                ? onAddAccount
                : () => _openAccountsSheet(
                      context,
                      title: 'Cash wallet',
                      list: cashAccounts,
                      emptyHint: 'No cash wallet yet.',
                    ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Section: 4. Budgets & Spending
  // ---------------------------------------------------------------------------

  Widget _buildBudgetsAndSpending(
    BuildContext context,
    SettingsPreferences prefs,
    CurrencySettings currency,
  ) {
    final limit = prefs.monthlySpendingLimit;
    return SettingsSection(
      title: 'Budgets & Spending',
      children: [
        SettingsTile(
          icon: Icons.account_balance_rounded,
          title: 'Monthly Spending Limit',
          subtitle: 'Global cap across all categories',
          valueLabel: limit == null ? 'Not set' : currency.format(limit),
          onTap: () => _editMonthlyLimit(context, prefs, currency),
        ),
        SettingsTile(
          icon: Icons.donut_small_rounded,
          title: 'Category Budgets',
          subtitle: 'Food, Shopping, Travel…',
          futureReady: true,
          onTap: () => _stub(context, 'Category budgets'),
        ),
        SettingsSwitchTile(
          icon: Icons.shield_moon_rounded,
          title: 'Safe Daily Spend',
          subtitle: 'Show a recommended daily spend amount',
          value: prefs.safeDailySpendEnabled,
          onChanged: prefs.setSafeDailySpendEnabled,
        ),
        SettingsSwitchTile(
          icon: Icons.warning_amber_rounded,
          title: 'Overspending Alerts',
          subtitle: 'Warn when nearing or over a budget',
          value: prefs.overspendingAlertsEnabled,
          onChanged: prefs.setOverspendingAlertsEnabled,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Section: 5. Notifications & Reminders
  // ---------------------------------------------------------------------------

  Widget _buildNotifications(BuildContext context, SettingsPreferences prefs) {
    return SettingsSection(
      title: 'Notifications & Reminders',
      children: [
        SettingsSwitchTile(
          icon: Icons.event_repeat_rounded,
          title: 'Recurring Payment Reminders',
          subtitle: 'EMIs, bills, subscriptions',
          value: prefs.notifRecurringEnabled,
          onChanged: prefs.setNotifRecurringEnabled,
        ),
        SettingsSwitchTile(
          icon: Icons.work_history_rounded,
          title: 'Salary Reminder',
          subtitle: 'Ping when your salary is expected',
          value: prefs.notifSalaryEnabled,
          onChanged: prefs.setNotifSalaryEnabled,
        ),
        SettingsSwitchTile(
          icon: Icons.notifications_active_rounded,
          title: 'Budget Alerts',
          subtitle: 'Nearing limits & overspending',
          value: prefs.notifBudgetEnabled,
          onChanged: prefs.setNotifBudgetEnabled,
        ),
        SettingsSwitchTile(
          icon: Icons.auto_awesome_rounded,
          title: 'Smart Insights',
          subtitle: 'Unusual spending & monthly summaries',
          value: prefs.notifInsightsEnabled,
          onChanged: prefs.setNotifInsightsEnabled,
        ),
        SettingsTile(
          icon: Icons.alarm_rounded,
          title: 'Notification Timing',
          subtitle: 'When reminders fire',
          valueLabel: prefs.notifTiming.label,
          onTap: () => _pickNotificationTiming(context, prefs),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Section: 6. AI Assistant Settings
  // ---------------------------------------------------------------------------

  Widget _buildAiAssistant(BuildContext context, SettingsPreferences prefs) {
    return SettingsSection(
      title: 'AI Assistant',
      children: [
        SettingsSwitchTile(
          icon: Icons.psychology_rounded,
          title: 'AI Assistant',
          subtitle: 'Enable AI features across the app',
          value: prefs.aiAssistantEnabled,
          onChanged: prefs.setAiAssistantEnabled,
        ),
        SettingsSwitchTile(
          icon: Icons.lightbulb_rounded,
          title: 'Suggested Insights',
          subtitle: 'Spending analysis & saving recommendations',
          value: prefs.aiInsightsEnabled,
          onChanged:
              prefs.aiAssistantEnabled ? prefs.setAiInsightsEnabled : (_) {},
          enabled: prefs.aiAssistantEnabled,
        ),
        const SettingsInfoTile(
          icon: Icons.privacy_tip_rounded,
          title: 'AI Data Usage',
          subtitle:
              'AI only analyzes financial data inside the app. Nothing leaves '
              'your account.',
        ),
        SettingsTile(
          icon: Icons.delete_sweep_rounded,
          title: 'Clear AI Chat History',
          subtitle: 'Remove past conversations from this device',
          destructive: true,
          onTap: () => _confirmClearAiHistory(context),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Section: 7. Data & Privacy
  // ---------------------------------------------------------------------------

  Widget _buildDataAndPrivacy(BuildContext context) {
    return SettingsSection(
      title: 'Data & Privacy',
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
          subtitle: 'Reads/writes work without internet — synced later',
          statusPill: 'Local-first',
        ),
        SettingsTile(
          icon: Icons.delete_forever_rounded,
          title: 'Delete Account',
          subtitle: 'Permanently remove your account and data',
          destructive: true,
          onTap: () => _stub(context, 'Account deletion'),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Section: 8. App Preferences
  // ---------------------------------------------------------------------------

  Widget _buildAppPreferences(
    BuildContext context,
    SettingsPreferences prefs,
  ) {
    return SettingsSection(
      title: 'App Preferences',
      footnote:
          'Light & System themes are coming soon — Dark stays the default.',
      children: [
        SettingsTile(
          icon: Icons.dark_mode_rounded,
          title: 'Theme',
          subtitle: 'Pick a global appearance',
          valueLabel: prefs.themeModePref.label,
          onTap: () => _pickThemeMode(context, prefs),
        ),
        SettingsTile(
          icon: Icons.lock_rounded,
          title: 'App Lock',
          subtitle: 'Biometrics or PIN on launch',
          futureReady: true,
          onTap: () => _stub(context, 'App lock'),
        ),
        SettingsSwitchTile(
          icon: Icons.vibration_rounded,
          title: 'Haptic Feedback',
          subtitle: 'Subtle taps on interactions',
          value: prefs.hapticEnabled,
          onChanged: prefs.setHapticEnabled,
        ),
        SettingsSwitchTile(
          icon: Icons.animation_rounded,
          title: 'Animations',
          subtitle: 'Turn off to reduce motion',
          value: prefs.animationsEnabled,
          onChanged: prefs.setAnimationsEnabled,
        ),
        SettingsSwitchTile(
          icon: Icons.density_small_rounded,
          title: 'Compact Mode',
          subtitle: 'Denser transaction list',
          value: prefs.compactModeEnabled,
          onChanged: prefs.setCompactModeEnabled,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Section: 9. Support & Feedback
  // ---------------------------------------------------------------------------

  Widget _buildSupportAndFeedback(BuildContext context) {
    return SettingsSection(
      title: 'Support & Feedback',
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
          icon: Icons.policy_rounded,
          title: 'Privacy Policy',
          onTap: () => _stub(context, 'Privacy policy'),
        ),
        SettingsTile(
          icon: Icons.gavel_rounded,
          title: 'Terms of Service',
          onTap: () => _stub(context, 'Terms of service'),
        ),
        const SettingsInfoTile(
          icon: Icons.info_outline_rounded,
          title: 'App Version',
          valueLabel: 'v1.0.0 (1)',
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers — bottom sheets, pickers, stubs
  // ---------------------------------------------------------------------------

  Future<void> _pickFinancialYear(
    BuildContext context,
    SettingsPreferences prefs,
  ) =>
      _showOptionSheet<FinancialYear>(
        context: context,
        title: 'Financial year',
        subtitle: 'Used for analytics, budgets, and year-over-year views.',
        current: prefs.financialYear,
        options: FinancialYear.values,
        labelFor: (v) => v.label,
        onPicked: prefs.setFinancialYear,
      );

  Future<void> _pickDefaultTransactionType(
    BuildContext context,
    SettingsPreferences prefs,
  ) =>
      _showOptionSheet<DefaultTransactionType>(
        context: context,
        title: 'Default transaction type',
        subtitle: 'The Add Transaction screen will open on this tab.',
        current: prefs.defaultTransactionType,
        options: DefaultTransactionType.values,
        labelFor: (v) => v.label,
        onPicked: prefs.setDefaultTransactionType,
      );

  Future<void> _pickNotificationTiming(
    BuildContext context,
    SettingsPreferences prefs,
  ) =>
      _showOptionSheet<NotificationTiming>(
        context: context,
        title: 'Notification timing',
        subtitle: 'When recurring & budget reminders fire.',
        current: prefs.notifTiming,
        options: NotificationTiming.values,
        labelFor: (v) => v.label,
        onPicked: prefs.setNotifTiming,
      );

  Future<void> _pickThemeMode(
    BuildContext context,
    SettingsPreferences prefs,
  ) =>
      _showOptionSheet<ThemeModePref>(
        context: context,
        title: 'Theme',
        subtitle: 'Currently the app renders in Dark. Other themes are coming '
            'soon — your choice is saved.',
        current: prefs.themeModePref,
        options: ThemeModePref.values,
        labelFor: (v) => v.label,
        onPicked: prefs.setThemeModePref,
      );

  Future<void> _pickExportFormat(BuildContext context) async {
    final picked = await _selectFromList<ExportFormat>(
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

  Future<void> _pickDefaultAccount(
    BuildContext context, {
    required int? currentId,
    required String title,
    required Future<void> Function(int?) onPicked,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.72,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xs,
                    AppSpacing.xl,
                    AppSpacing.sm,
                  ),
                  child: Text(title, style: AppTextStyles.headingSmall),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Text(
                    'Preselected when you open Add Transaction.',
                    style: AppTextStyles.caption,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    children: [
                      _AccountPickerRow(
                        title: 'Auto',
                        subtitle: 'Use the most recently used account',
                        selected: currentId == null,
                        icon: Icons.auto_awesome_rounded,
                        onTap: () async {
                          await onPicked(null);
                          if (!sheetContext.mounted) return;
                          Navigator.of(sheetContext).pop();
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (accounts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Text(
                            'No accounts yet. Add one from Accounts & Cards.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium,
                          ),
                        )
                      else
                        ...accounts.map(
                          (account) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _AccountPickerRow(
                              title: account.name,
                              subtitle: account.type.label,
                              selected: currentId == account.id,
                              icon: _iconForAccountType(account.type),
                              onTap: () async {
                                await onPicked(account.id);
                                if (!sheetContext.mounted) return;
                                Navigator.of(sheetContext).pop();
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openAccountsSheet(
    BuildContext context, {
    required String title,
    required List<Account> list,
    required String emptyHint,
    List<Widget> extraTiles = const [],
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.72;
        return SafeArea(
          child: SizedBox(
            height: maxHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xs,
                    AppSpacing.xl,
                    AppSpacing.sm,
                  ),
                  child: Text(title, style: AppTextStyles.headingSmall),
                ),
                Expanded(
                  child: list.isEmpty && extraTiles.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Text(
                              emptyHint,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            AppSpacing.md,
                          ),
                          children: [
                            for (final account in list) ...[
                              _AccountListRow(account: account),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                            if (extraTiles.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: AppRadii.cardRadius,
                                  border:
                                      Border.all(color: AppColors.border),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  children: [
                                    for (var i = 0;
                                        i < extraTiles.length;
                                        i++) ...[
                                      extraTiles[i],
                                      if (i != extraTiles.length - 1)
                                        const Divider(
                                          height: 1,
                                          thickness: 1,
                                          color: AppColors.border,
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editMonthlyLimit(
    BuildContext context,
    SettingsPreferences prefs,
    CurrencySettings currency,
  ) async {
    final controller = TextEditingController(
      text: prefs.monthlySpendingLimit?.toStringAsFixed(0) ?? '',
    );
    try {
      final saved = await showModalBottomSheet<bool>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        builder: (sheetContext) {
          final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xs,
                  AppSpacing.xl,
                  AppSpacing.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Monthly spending limit',
                      style: AppTextStyles.headingSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Sets a soft cap. We will warn before you cross it.',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        prefixText: currency.inputPrefix,
                        labelText: 'Amount',
                        hintText: '0',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              await prefs.setMonthlySpendingLimit(null);
                              if (!sheetContext.mounted) return;
                              Navigator.of(sheetContext).pop(true);
                            },
                            style: OutlinedButton.styleFrom(
                              side:
                                  const BorderSide(color: AppColors.border),
                              foregroundColor: AppColors.textPrimary,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                            child: const Text('Clear'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              final raw = controller.text.trim();
                              final value = double.tryParse(raw);
                              if (value == null || value <= 0) {
                                SnackbarHelper.showMessage(
                                  sheetContext,
                                  'Enter a positive amount',
                                );
                                return;
                              }
                              await prefs.setMonthlySpendingLimit(value);
                              if (!sheetContext.mounted) return;
                              Navigator.of(sheetContext).pop(true);
                            },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      if (saved == true && context.mounted) {
        SnackbarHelper.showSuccess(context, 'Monthly limit updated');
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _confirmClearAiHistory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear AI history'),
        content: const Text(
          'This removes all AI conversations stored on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.textPrimary,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      SnackbarHelper.showSuccess(context, 'AI chat history cleared');
    }
  }

  Future<void> _showOptionSheet<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    required T current,
    required List<T> options,
    required String Function(T) labelFor,
    required Future<void> Function(T) onPicked,
  }) async {
    final picked = await _selectFromList<T>(
      context: context,
      title: title,
      subtitle: subtitle,
      current: current,
      options: options,
      labelFor: labelFor,
    );
    if (picked != null) {
      await onPicked(picked);
    }
  }

  Future<T?> _selectFromList<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    required T? current,
    required List<T> options,
    required String Function(T) labelFor,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xs,
                  AppSpacing.xl,
                  AppSpacing.sm,
                ),
                child: Text(title, style: AppTextStyles.headingSmall),
              ),
              if (subtitle != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Text(subtitle, style: AppTextStyles.caption),
                ),
              const SizedBox(height: AppSpacing.sm),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                itemCount: options.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final option = options[index];
                  final selected = current != null && option == current;
                  return _SelectableRow(
                    label: labelFor(option),
                    selected: selected,
                    onTap: () => Navigator.of(sheetContext).pop(option),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _stub(BuildContext context, String label) {
    SnackbarHelper.showMessage(context, '$label is coming soon');
  }

  // ---------------------------------------------------------------------------
  // Computed values
  // ---------------------------------------------------------------------------

  String _profileInitial() {
    final email = _email();
    if (email.isEmpty || email == 'Unknown user') return '?';
    return email.characters.first.toUpperCase();
  }

  String _displayName() {
    final email = _email();
    if (email.isEmpty || email == 'Unknown user') return 'Your profile';
    final at = email.indexOf('@');
    if (at <= 0) return email;
    final local = email.substring(0, at);
    if (local.isEmpty) return email;
    return local[0].toUpperCase() + local.substring(1);
  }

  String _email() => SupabaseService.currentUser?.email ?? 'Unknown user';

  double _monthSpent() {
    final now = DateTime.now();
    return expenses
        .where(
          (e) => e.date.year == now.year && e.date.month == now.month,
        )
        .fold<double>(0, (sum, e) => sum + e.amount);
  }

  int _recurringCount() => expenses.where((e) => e.isRecurring).length;

  String? _accountNameForId(int? id) {
    if (id == null) return null;
    for (final a in accounts) {
      if (a.id == id) return a.name;
    }
    return null;
  }

  String _countLabel(int count, String singular, String plural) {
    if (count == 0) return 'None yet';
    if (count == 1) return '1 $singular';
    return '$count $plural';
  }

  IconData _iconForAccountType(AccountType type) {
    switch (type) {
      case AccountType.bank:
        return Icons.account_balance_rounded;
      case AccountType.creditCard:
        return Icons.credit_card_rounded;
      case AccountType.cash:
        return Icons.savings_rounded;
      case AccountType.other:
        return Icons.account_balance_wallet_rounded;
    }
  }
}

class _AccountPickerRow extends StatelessWidget {
  const _AccountPickerRow({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withAlpha(28)
          : AppColors.surfaceSecondary,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withAlpha(110)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(28),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.caption),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountListRow extends StatelessWidget {
  const _AccountListRow({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final icon = switch (account.type) {
      AccountType.bank => Icons.account_balance_rounded,
      AccountType.creditCard => Icons.credit_card_rounded,
      AccountType.cash => Icons.savings_rounded,
      AccountType.other => Icons.account_balance_wallet_rounded,
    };
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(28),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        title: Text(
          account.name,
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(account.type.label, style: AppTextStyles.caption),
      ),
    );
  }
}

class _SelectableRow extends StatelessWidget {
  const _SelectableRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withAlpha(28)
          : AppColors.surfaceSecondary,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withAlpha(110)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight:
                        selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
