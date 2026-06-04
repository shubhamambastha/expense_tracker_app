import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/design_tokens.dart';
import '../../models/transaction_draft.dart';
import '../../services/currency_settings.dart';
import '../../utils/emi_schedule_helpers.dart';
import '../../utils/transaction_subtype_helpers.dart';
import 'quick_ai_input.dart';
import 'recent_suggestions_section.dart';
import 'recurring_payment_section.dart';
import 'transaction_subtype_chips.dart';

/// Collapsible Advanced block — note, recurring, subtypes, suggestions, etc.
class TransactionAdvancedSection extends StatelessWidget {
  const TransactionAdvancedSection({
    super.key,
    required this.expanded,
    required this.onExpandToggle,
    required this.kind,
    required this.categoryName,
    required this.amount,
    required this.recurring,
    required this.noteController,
    required this.onRecurringChanged,
    required this.onPickStartDate,
    required this.onPickEndDate,
    required this.onSubtypeSelected,
    required this.onIncomeRefundSelected,
    required this.onQuickParse,
    required this.onSaveAndAddAnother,
    this.onSuggestionTap,
    this.recentSuggestions = const [],
    this.recentIncomeSuggestions = const [],
    this.isBusy = false,
    this.showSaveAndAddAnother = true,
    this.noteHintText = 'Add a note (optional)',
    this.reminderHint,
  });

  final bool expanded;
  final VoidCallback onExpandToggle;
  final TransactionKind kind;
  final String? categoryName;
  final double? amount;
  final RecurringConfig recurring;
  final TextEditingController noteController;
  final ValueChanged<RecurringConfig> onRecurringChanged;
  final Future<void> Function() onPickStartDate;
  final Future<void> Function() onPickEndDate;
  final ValueChanged<String> onSubtypeSelected;
  final VoidCallback onIncomeRefundSelected;
  final ValueChanged<String> onQuickParse;
  final VoidCallback onSaveAndAddAnother;
  final ValueChanged<RecentSuggestion>? onSuggestionTap;
  final List<RecentSuggestion> recentSuggestions;
  final List<RecentSuggestion> recentIncomeSuggestions;
  final bool isBusy;
  final bool showSaveAndAddAnother;
  final String noteHintText;
  final String? reminderHint;

  bool get _isEmi => TransactionSubtypeHelpers.isEmiCategory(categoryName);
  bool get _isSubscription =>
      TransactionSubtypeHelpers.isSubscriptionCategory(categoryName);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.sm),
        const Divider(height: 1, thickness: 1, color: AppColors.border),
        InkWell(
          onTap: onExpandToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Text(
                  'Advanced',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  duration: AppDurations.micro,
                  curve: AppCurves.spring,
                  turns: expanded ? 0.5 : 0,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: AppDurations.page,
          curve: AppCurves.emphasized,
          alignment: Alignment.topCenter,
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AdvancedFieldLabel(label: 'Note'),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: noteController,
                        maxLines: 1,
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.sentences,
                        style: AppTextStyles.bodyMedium,
                        decoration: InputDecoration(
                          hintText: noteHintText,
                          prefixIcon: const Icon(
                            Icons.notes_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (kind == TransactionKind.expense) ...[
                        _AdvancedFieldLabel(label: 'Quick type'),
                        const SizedBox(height: AppSpacing.sm),
                        ExpenseSubtypeChips(
                          selectedCategory: categoryName,
                          onSubtypeSelected: onSubtypeSelected,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      if (kind == TransactionKind.income) ...[
                        _AdvancedFieldLabel(label: 'Quick type'),
                        const SizedBox(height: AppSpacing.sm),
                        IncomeRefundChip(
                          selectedCategory: categoryName,
                          onSelected: onIncomeRefundSelected,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      if (_isEmi) ...[
                        _EmiDetailsBlock(
                          amount: amount,
                          recurring: recurring,
                          onRecurringChanged: onRecurringChanged,
                          onPickStartDate: onPickStartDate,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      RecurringPaymentSection(
                        config: recurring,
                        onChanged: onRecurringChanged,
                        onPickStartDate: onPickStartDate,
                        onPickEndDate: onPickEndDate,
                        isIncome: kind == TransactionKind.income,
                        reminderHint: reminderHint,
                        compact: true,
                        showReminder: !_isSubscription,
                      ),
                      if (recentSuggestions.isNotEmpty &&
                          kind == TransactionKind.expense) ...[
                        const SizedBox(height: AppSpacing.lg),
                        RecentSuggestionsSection(
                          suggestions: recentSuggestions,
                          onTap: onSuggestionTap ?? (_) {},
                        ),
                      ],
                      if (recentIncomeSuggestions.isNotEmpty &&
                          kind == TransactionKind.income) ...[
                        const SizedBox(height: AppSpacing.lg),
                        RecentSuggestionsSection(
                          suggestions: recentIncomeSuggestions,
                          title: 'Recent income',
                          showCategoryPrefix: true,
                          onTap: onSuggestionTap ?? (_) {},
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      QuickAiInput(onParse: onQuickParse),
                      const SizedBox(height: AppSpacing.lg),
                      _SoonRow(
                        icon: Icons.attach_file_rounded,
                        title: 'Attachments',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _SoonRow(
                        icon: Icons.data_object_rounded,
                        title: 'Custom Metadata',
                      ),
                      if (showSaveAndAddAnother) ...[
                        const SizedBox(height: AppSpacing.lg),
                        OutlinedButton(
                          onPressed: isBusy ? null : onSaveAndAddAnother,
                          child: const Text('Save & Add Another'),
                        ),
                      ],
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _AdvancedFieldLabel extends StatelessWidget {
  const _AdvancedFieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.label.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SoonRow extends StatelessWidget {
  const _SoonRow({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.7,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.secondary.withAlpha(28),
              borderRadius: AppRadii.pillRadius,
              border: Border.all(color: AppColors.secondary.withAlpha(70)),
            ),
            child: Text(
              'Soon',
              style: AppTextStyles.label.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmiDetailsBlock extends StatelessWidget {
  const _EmiDetailsBlock({
    required this.amount,
    required this.recurring,
    required this.onRecurringChanged,
    required this.onPickStartDate,
  });

  final double? amount;
  final RecurringConfig recurring;
  final ValueChanged<RecurringConfig> onRecurringChanged;
  final Future<void> Function() onPickStartDate;

  int get _tenureMonths {
    final end = recurring.endDate;
    if (end == null) return 12;
    return EmiScheduleHelpers.tenureMonthsFromDates(
      start: recurring.startDate,
      end: end,
    );
  }

  int get _remaining {
    final end = recurring.endDate;
    if (end == null) return _tenureMonths;
    return EmiScheduleHelpers.remainingInstallments(endDate: end);
  }

  String get _amountLabel {
    final value = amount;
    if (value == null || value <= 0) return 'Uses amount above';
    final currency = CurrencySettings.instance;
    return '${currency.symbol}${value.toStringAsFixed(currency.decimalDigits)} / month';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _AdvancedFieldLabel(label: 'EMI Details'),
        const SizedBox(height: AppSpacing.sm),
        _EmiInfoRow(label: 'EMI amount', value: _amountLabel),
        const SizedBox(height: AppSpacing.sm),
        InkWell(
          onTap: onPickStartDate,
          borderRadius: AppRadii.inputRadius,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: AppRadii.inputRadius,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Text('Start date', style: AppTextStyles.label),
                const Spacer(),
                Text(
                  DateFormat.MMMd().format(recurring.startDate),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _TenureStepper(
                label: 'Total tenure',
                value: _tenureMonths,
                suffix: 'mo',
                onChanged: (months) {
                  onRecurringChanged(
                    recurring.copyWith(
                      enabled: true,
                      endDate: EmiScheduleHelpers.endDateFromTenure(
                        startDate: recurring.startDate,
                        tenureMonths: months,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _EmiInfoRow(
                label: 'Remaining',
                value: '$_remaining mo',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmiInfoRow extends StatelessWidget {
  const _EmiInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: AppRadii.inputRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TenureStepper extends StatelessWidget {
  const _TenureStepper({
    required this.label,
    required this.value,
    required this.suffix,
    required this.onChanged,
  });

  final String label;
  final int value;
  final String suffix;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: AppRadii.inputRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepButton(
                icon: Icons.remove_rounded,
                onTap: value > 1 ? () => onChanged(value - 1) : null,
              ),
              Expanded(
                child: Text(
                  '$value $suffix',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StepButton(
                icon: Icons.add_rounded,
                onTap: value < 999 ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppColors.primary.withAlpha(28)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null
              ? AppColors.primary
              : AppColors.textSecondary.withAlpha(120),
        ),
      ),
    );
  }
}
