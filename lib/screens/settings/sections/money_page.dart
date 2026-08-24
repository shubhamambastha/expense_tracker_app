import 'package:flutter/material.dart';

import '../../../components/settings/currency_picker_sheet.dart';
import '../../../components/settings/settings_picker_helpers.dart';
import '../../../components/settings/settings_section.dart';
import '../../../components/settings/settings_subpage_scaffold.dart';
import '../../../components/settings/settings_tile.dart';
import '../../../config/design_tokens.dart';
import '../../../models/account.dart';
import '../../../models/expense.dart' show AccountTypeLabel;
import '../../../services/category_catalog.dart';
import '../../../services/currency_settings.dart';
import '../../../services/income_category_catalog.dart';
import '../../../services/settings_preferences.dart';
import 'appearance_page.dart';
import 'categories_page.dart';

/// Thin hub for everything about your money — currency, appearance,
/// accounts, categories, recurring payments, and a shortcut to Budgets.
///
/// Deliberately a navigation hub, not an inline mega-page: rows push to
/// the existing unchanged subpages (Appearance, Categories) or call the
/// existing shared callbacks (Accounts & Cards, Recurring Payments) — the
/// same pattern the top-level Settings hub already uses. Only Base
/// Currency and Default Expense Account render inline, since they're each
/// a single row, not a whole subpage's worth of content.
class MoneyPage extends StatelessWidget {
  const MoneyPage({
    super.key,
    required this.accounts,
    required this.onManageAccounts,
    required this.onOpenRecurringManager,
    required this.onOpenBudgets,
  });

  final List<Account> accounts;
  final VoidCallback onManageAccounts;
  final VoidCallback onOpenRecurringManager;

  /// Leaves the Settings tab entirely and switches to the Budgets tab —
  /// Budgets is a sibling primary tab, not a Settings subpage.
  final VoidCallback onOpenBudgets;

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

        return SettingsSubpageScaffold(
          title: 'Money',
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
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SettingsSection(
              title: 'Appearance',
              children: [
                SettingsTile(
                  icon: Icons.dark_mode_rounded,
                  title: 'Appearance',
                  valueLabel: prefs.themeMode == ThemeMode.light
                      ? 'Light'
                      : 'Dark',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AppearancePage(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SettingsSection(
              title: 'Data',
              children: [
                SettingsTile(
                  icon: Icons.outbox_rounded,
                  title: 'Default Expense Account',
                  subtitle: 'Shown as your default in Accounts & Cards',
                  valueLabel:
                      _accountNameForId(prefs.defaultExpenseAccountId) ??
                      'Auto',
                  onTap: () => _pickDefaultExpenseAccount(context, prefs),
                ),
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
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CategoriesPage(),
                    ),
                  ),
                ),
                SettingsTile(
                  icon: Icons.autorenew_rounded,
                  title: 'Recurring Payments',
                  onTap: onOpenRecurringManager,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SettingsSection(
              title: 'Budgets',
              children: [
                SettingsTile(
                  icon: Icons.donut_small_rounded,
                  title: 'Open Budgets',
                  subtitle: 'Switches to the Budgets tab',
                  onTap: onOpenBudgets,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickDefaultExpenseAccount(
    BuildContext context,
    SettingsPreferences prefs,
  ) async {
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
                  child: Text(
                    'Default expense account',
                    style: AppTextStyles.headingSmall,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Text(
                    'Shown as your default account in Accounts & Cards.',
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
                        selected: prefs.defaultExpenseAccountId == null,
                        icon: Icons.auto_awesome_rounded,
                        onTap: () async {
                          await prefs.setDefaultExpenseAccountId(null);
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
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: SettingsAccountPickerRow(
                              title: account.name,
                              subtitle: account.type.label,
                              selected:
                                  prefs.defaultExpenseAccountId == account.id,
                              icon: iconForAccountType(account.type),
                              onTap: () async {
                                await prefs.setDefaultExpenseAccountId(
                                  account.id,
                                );
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

  String _accountsSummary() {
    final total = accounts.length;
    if (total == 0) return 'None yet';
    if (total == 1) return '1 linked';
    return '$total linked';
  }

  String _categoriesSummary() {
    final total =
        CategoryCatalog.instance.categories.length +
        IncomeCategoryCatalog.instance.categories.length;
    if (total == 0) return 'None yet';
    if (total == 1) return '1 label';
    return '$total labels';
  }
}
