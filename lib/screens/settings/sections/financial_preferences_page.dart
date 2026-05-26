import 'package:flutter/material.dart';

import '../../../components/settings/currency_picker_sheet.dart';
import '../../../components/settings/settings_picker_helpers.dart';
import '../../../components/settings/settings_section.dart';
import '../../../components/settings/settings_subpage_scaffold.dart';
import '../../../components/settings/settings_switch_tile.dart';
import '../../../components/settings/settings_tile.dart';
import '../../../config/design_tokens.dart';
import '../../../models/account.dart';
import '../../../models/expense.dart';
import '../../../services/currency_settings.dart';
import '../../../services/settings_preferences.dart';

/// Dedicated screen for "Financial Preferences" — the subset of settings that
/// affect how transactions are interpreted, which currency is used for
/// roll-ups, and which defaults pre-populate the Add Transaction form.
class FinancialPreferencesPage extends StatelessWidget {
  const FinancialPreferencesPage({super.key, required this.accounts});

  final List<Account> accounts;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        CurrencySettings.instance,
        SettingsPreferences.instance,
      ]),
      builder: (context, _) {
        final currency = CurrencySettings.instance;
        final prefs = SettingsPreferences.instance;

        return SettingsSubpageScaffold(
          title: 'Financial Preferences',
          subtitle:
              'Currency, fiscal year, and the defaults the app uses when '
              'you add a new transaction.',
          children: [
            SettingsSection(
              title: 'Currency',
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
                  subtitle:
                      'Track foreign currencies on individual entries',
                  value: prefs.multiCurrencyEnabled,
                  onChanged: prefs.setMultiCurrencyEnabled,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SettingsSection(
              title: 'Defaults',
              children: [
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
                  valueLabel: _accountNameForId(
                        prefs.defaultExpenseAccountId,
                      ) ??
                      'Auto',
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
                      _accountNameForId(prefs.defaultIncomeAccountId) ??
                          'Auto',
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
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickFinancialYear(
    BuildContext context,
    SettingsPreferences prefs,
  ) =>
      showSettingsOptionSheet<FinancialYear>(
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
      showSettingsOptionSheet<DefaultTransactionType>(
        context: context,
        title: 'Default transaction type',
        subtitle: 'The Add Transaction screen will open on this tab.',
        current: prefs.defaultTransactionType,
        options: DefaultTransactionType.values,
        labelFor: (v) => v.label,
        onPicked: prefs.setDefaultTransactionType,
      );

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
                      SettingsAccountPickerRow(
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
                            child: SettingsAccountPickerRow(
                              title: account.name,
                              subtitle: account.type.label,
                              selected: currentId == account.id,
                              icon: iconForAccountType(account.type),
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

  String? _accountNameForId(int? id) {
    if (id == null) return null;
    for (final a in accounts) {
      if (a.id == id) return a.name;
    }
    return null;
  }
}
