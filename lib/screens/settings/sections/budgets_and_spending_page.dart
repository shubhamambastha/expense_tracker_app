import 'package:flutter/material.dart';

import '../../../components/settings/settings_section.dart';
import '../../../components/settings/settings_subpage_scaffold.dart';
import '../../../components/settings/settings_switch_tile.dart';
import '../../../components/settings/settings_tile.dart';
import '../../../config/design_tokens.dart';
import '../../../services/currency_settings.dart';
import '../../../services/settings_preferences.dart';
import '../../../utils/snackbar_helper.dart';

/// Caps, category-level budgets, and the soft warnings that go with them.
class BudgetsAndSpendingPage extends StatelessWidget {
  const BudgetsAndSpendingPage({super.key});

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
        final limit = prefs.monthlySpendingLimit;

        return SettingsSubpageScaffold(
          title: 'Budgets & Spending',
          subtitle:
              'Set a monthly cap and pick how aggressive the app should be '
              'when you approach it.',
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
                  futureReady: true,
                  onTap: () => _stub(context, 'Category budgets'),
                ),
              ],
            ),
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

  void _stub(BuildContext context, String label) {
    SnackbarHelper.showMessage(context, '$label is coming soon');
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
                        side: const BorderSide(color: AppColors.border),
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
  }
}
