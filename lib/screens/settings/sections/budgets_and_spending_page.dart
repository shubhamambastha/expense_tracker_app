import 'package:flutter/material.dart';

import '../../../components/home/dashboard/budget_edit_sheet.dart';
import '../../../components/settings/settings_section.dart';
import '../../../components/settings/settings_switch_tile.dart';
import '../../../components/settings/settings_tile.dart';
import '../../../config/design_tokens.dart';
import '../../../models/category_budget.dart';
import '../../../services/category_budget_service.dart';
import '../../../services/currency_settings.dart';
import '../../../services/settings_preferences.dart';
import '../../../utils/snackbar_helper.dart';

/// Body of the Budgets & Spending screen — caps, category-level budgets,
/// and the soft warnings that go with them. No scaffold/header of its own;
/// rendered under the Budgets tab's large-title header.
class BudgetsAndSpendingContent extends StatefulWidget {
  const BudgetsAndSpendingContent({super.key});

  @override
  State<BudgetsAndSpendingContent> createState() =>
      _BudgetsAndSpendingContentState();
}

class _BudgetsAndSpendingContentState
    extends State<BudgetsAndSpendingContent> {
  @override
  void initState() {
    super.initState();
    CategoryBudgetService.instance.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        CurrencySettings.instance,
        SettingsPreferences.instance,
        CategoryBudgetService.instance,
      ]),
      builder: (context, _) {
        final currency = CurrencySettings.instance;
        final prefs = SettingsPreferences.instance;
        final limit = prefs.monthlySpendingLimit;
        final budgets = CategoryBudgetService.instance.budgets;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsSection(
              title: 'Limits',
              children: [
                SettingsTile(
                  icon: Icons.account_balance_rounded,
                  title: 'Monthly Spending Limit',
                  subtitle: 'Global cap across all categories',
                  valueLabel:
                      limit == null ? 'Not set' : currency.format(limit),
                  onTap: () => _editMonthlyLimit(context, prefs, currency),
                ),
                SettingsTile(
                  icon: Icons.donut_small_rounded,
                  title: 'Category Budgets',
                  subtitle: 'Food, Shopping, Travel…',
                  valueLabel: budgets.isEmpty
                      ? 'None'
                      : '${budgets.length} active',
                  onTap: () => showBudgetEditSheet(context),
                ),
              ],
            ),
            if (budgets.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              SettingsSection(
                title: 'Active category budgets',
                children: [
                  for (final budget in budgets)
                    _CategoryBudgetTile(budget: budget),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            SettingsSection(
              title: 'Guardrails',
              children: [
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
                  futureReady: true,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _editMonthlyLimit(
    BuildContext context,
    SettingsPreferences prefs,
    CurrencySettings currency,
  ) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => _MonthlyLimitSheet(
        prefs: prefs,
        currency: currency,
        initialText: prefs.monthlySpendingLimit?.toStringAsFixed(0) ?? '',
      ),
    );

    if (saved == true && context.mounted) {
      SnackbarHelper.showSuccess(context, 'Monthly limit updated');
    }
  }
}

class _CategoryBudgetTile extends StatelessWidget {
  const _CategoryBudgetTile({required this.budget});

  final CategoryBudget budget;

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;
    return SettingsTile(
      icon: Icons.donut_large_rounded,
      title: budget.categoryName,
      subtitle: 'Monthly cap',
      valueLabel: currency.format(budget.monthlyLimit),
      onTap: () => showBudgetEditSheet(context, initial: budget),
    );
  }
}

/// Owns the [TextEditingController] for the monthly limit sheet so disposal
/// happens in [State.dispose] after the route is removed.
class _MonthlyLimitSheet extends StatefulWidget {
  const _MonthlyLimitSheet({
    required this.prefs,
    required this.currency,
    required this.initialText,
  });

  final SettingsPreferences prefs;
  final CurrencySettings currency;
  final String initialText;

  @override
  State<_MonthlyLimitSheet> createState() => _MonthlyLimitSheetState();
}

class _MonthlyLimitSheetState extends State<_MonthlyLimitSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

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
                controller: _controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  prefixText: widget.currency.inputPrefix,
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
                        await widget.prefs.setMonthlySpendingLimit(null);
                        if (!context.mounted) return;
                        Navigator.of(context).pop(true);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.border),
                        foregroundColor: AppColors.textPrimary,
                      ),
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        final raw = _controller.text.trim();
                        final value = double.tryParse(raw);
                        if (value == null || value <= 0) {
                          SnackbarHelper.showMessage(
                            context,
                            'Enter a positive amount',
                          );
                          return;
                        }
                        await widget.prefs.setMonthlySpendingLimit(value);
                        if (!context.mounted) return;
                        Navigator.of(context).pop(true);
                      },
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
  }
}
