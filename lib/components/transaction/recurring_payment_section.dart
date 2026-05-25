import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/design_tokens.dart';
import '../../models/transaction_draft.dart';
import 'smart_contextual_fields.dart';

/// Collapsible "Recurring Payment" card with all the recurring-only fields
/// inside (frequency, reminder, start, end). Smart contextual
/// fields render here too when the category is EMI / Subscription —
/// progressive disclosure means *nothing* recurring-specific is visible
/// until the user opts in via the header toggle.
class RecurringPaymentSection extends StatelessWidget {
  const RecurringPaymentSection({
    super.key,
    required this.config,
    required this.onChanged,
    required this.onPickStartDate,
    required this.onPickEndDate,
    required this.showContextualFields,
    required this.contextualCategory,
    this.isIncome = false,
    this.reminderHint,
  });

  final RecurringConfig config;
  final ValueChanged<RecurringConfig> onChanged;
  final Future<void> Function() onPickStartDate;
  final Future<void> Function() onPickEndDate;
  final bool showContextualFields;
  final String? contextualCategory;
  final bool isIncome;
  final String? reminderHint;

  @override
  Widget build(BuildContext context) {
    final expanded = config.enabled;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(
          color: expanded
              ? AppColors.secondary.withAlpha(110)
              : AppColors.border,
          width: expanded ? 1.2 : 1,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          _Header(
            enabled: expanded,
            isIncome: isIncome,
            onToggle: (value) {
              onChanged(config.copyWith(enabled: value));
            },
          ),
          AnimatedSize(
            duration: AppDurations.page,
            curve: AppCurves.emphasized,
            alignment: Alignment.topCenter,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppRadii.card),
              ),
              child: expanded
                  ? _ExpandedBody(
                      config: config,
                      onChanged: onChanged,
                      onPickStartDate: onPickStartDate,
                      onPickEndDate: onPickEndDate,
                      showContextualFields: showContextualFields,
                      contextualCategory: contextualCategory,
                      isIncome: isIncome,
                      reminderHint: reminderHint,
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.enabled,
    required this.onToggle,
    this.isIncome = false,
  });

  final bool enabled;
  final ValueChanged<bool> onToggle;
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    final accent =
        enabled ? AppColors.secondary : AppColors.textSecondary;

    return InkWell(
      onTap: () => onToggle(!enabled),
      borderRadius: enabled
          ? const BorderRadius.vertical(top: Radius.circular(AppRadii.card))
          : AppRadii.cardRadius,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: AppDurations.micro,
              curve: AppCurves.spring,
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withAlpha(enabled ? 48 : 28),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                Icons.autorenew_rounded,
                size: 18,
                color: accent,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isIncome ? 'Recurring Income' : 'Recurring Payment',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    enabled
                        ? (isIncome
                            ? 'Repeat salary, rent, or retainers on a schedule.'
                            : 'Automate this transaction on a schedule.')
                        : (isIncome
                            ? 'Turn on for monthly salary or rental income.'
                            : 'Turn on to repeat this transaction.'),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: enabled,
              onChanged: onToggle,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandedBody extends StatelessWidget {
  const _ExpandedBody({
    required this.config,
    required this.onChanged,
    required this.onPickStartDate,
    required this.onPickEndDate,
    required this.showContextualFields,
    required this.contextualCategory,
    this.isIncome = false,
    this.reminderHint,
  });

  final RecurringConfig config;
  final ValueChanged<RecurringConfig> onChanged;
  final Future<void> Function() onPickStartDate;
  final Future<void> Function() onPickEndDate;
  final bool showContextualFields;
  final String? contextualCategory;
  final bool isIncome;
  final String? reminderHint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.md),
          const _SectionLabel(label: 'Frequency'),
          const SizedBox(height: AppSpacing.sm),
          _FrequencyWrap(
            selected: config.frequency,
            isIncome: isIncome,
            onChanged: (value) =>
                onChanged(config.copyWith(frequency: value)),
          ),
          const SizedBox(height: AppSpacing.md),
          const _SectionLabel(label: 'Reminder'),
          if (reminderHint != null) ...[
            const SizedBox(height: 4),
            Text(reminderHint!, style: AppTextStyles.caption),
          ],
          const SizedBox(height: AppSpacing.sm),
          _ReminderWrap(
            selected: config.reminder,
            onChanged: (value) =>
                onChanged(config.copyWith(reminder: value)),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _DatePickerTile(
                  label: 'Start',
                  value: DateFormat.MMMd().format(config.startDate),
                  icon: Icons.event_available_rounded,
                  accent: AppColors.primary,
                  onTap: onPickStartDate,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _DatePickerTile(
                  label: 'Ends',
                  value: config.endDate == null
                      ? 'Optional'
                      : DateFormat.MMMd().format(config.endDate!),
                  icon: Icons.event_busy_rounded,
                  accent: AppColors.textSecondary,
                  onTap: onPickEndDate,
                  trailing: config.endDate == null
                      ? null
                      : InkWell(
                          onTap: () =>
                              onChanged(config.copyWith(clearEndDate: true)),
                          borderRadius: BorderRadius.circular(10),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: AppDurations.page,
            curve: AppCurves.emphasized,
            alignment: Alignment.topCenter,
            child: showContextualFields
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: SmartContextualFields(
                      categoryName: contextualCategory ?? '',
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTextStyles.label);
  }
}

class _FrequencyWrap extends StatelessWidget {
  const _FrequencyWrap({
    required this.selected,
    required this.onChanged,
    this.isIncome = false,
  });

  final RecurrenceFrequency selected;
  final ValueChanged<RecurrenceFrequency> onChanged;
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    final frequencies = isIncome
        ? RecurrenceFrequency.values
            .where((f) => f != RecurrenceFrequency.daily)
            .toList()
        : RecurrenceFrequency.values;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final value in frequencies)
          _ChoiceChip(
            label: value.label,
            selected: value == selected,
            onTap: () => onChanged(value),
          ),
      ],
    );
  }
}

class _ReminderWrap extends StatelessWidget {
  const _ReminderWrap({required this.selected, required this.onChanged});

  final ReminderTiming selected;
  final ValueChanged<ReminderTiming> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final value in ReminderTiming.values)
          _ChoiceChip(
            label: value.label,
            selected: value == selected,
            onTap: () => onChanged(value),
          ),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.primary : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.chipRadius,
      child: AnimatedContainer(
        duration: AppDurations.micro,
        curve: AppCurves.spring,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withAlpha(32)
              : AppColors.surfaceSecondary,
          borderRadius: AppRadii.chipRadius,
          border: Border.all(
            color: selected
                ? AppColors.primary.withAlpha(140)
                : AppColors.border,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySmall.copyWith(
            color: fg,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final Future<void> Function() onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.inputRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: AppRadii.inputRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: accent),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.label),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
          ],
        ),
      ),
    );
  }
}
