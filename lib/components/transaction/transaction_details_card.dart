import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/design_tokens.dart';

/// Expandable card that groups secondary fields: date and note. Currency lives
/// on the amount hero.
///
/// The card is collapsible so the screen stays compact on first open. The
/// merchant input lives in the header so even when collapsed the most-used
/// field is reachable.
/// Whether merchant lives in the card header (expense) or elsewhere (income).
enum TransactionDetailsLayout { expenseWithMerchant, incomeSecondaryOnly }

class TransactionDetailsCard extends StatelessWidget {
  const TransactionDetailsCard({
    super.key,
    required this.expanded,
    required this.onExpandToggle,
    required this.date,
    required this.onPickDate,
    required this.onQuickDate,
    required this.noteController,
    this.layout = TransactionDetailsLayout.expenseWithMerchant,
    this.merchantController,
    this.merchantFocus,
    this.noteHintText = 'Add a note (optional)',
  });

  final bool expanded;
  final VoidCallback onExpandToggle;
  final TransactionDetailsLayout layout;

  final TextEditingController? merchantController;
  final FocusNode? merchantFocus;

  final DateTime date;
  final Future<void> Function() onPickDate;
  final ValueChanged<DateQuickOption> onQuickDate;

  final TextEditingController noteController;
  final String noteHintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          _Header(
            expanded: expanded,
            onTap: onExpandToggle,
            layout: layout,
            merchantController: merchantController,
            merchantFocus: merchantFocus,
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
                      date: date,
                      onPickDate: onPickDate,
                      onQuickDate: onQuickDate,
                      noteController: noteController,
                      noteHintText: noteHintText,
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick-date options for the [TransactionDetailsCard] date row.
enum DateQuickOption { today, yesterday, pick }

class _Header extends StatelessWidget {
  const _Header({
    required this.expanded,
    required this.onTap,
    required this.layout,
    this.merchantController,
    this.merchantFocus,
  });

  final bool expanded;
  final VoidCallback onTap;
  final TransactionDetailsLayout layout;
  final TextEditingController? merchantController;
  final FocusNode? merchantFocus;

  @override
  Widget build(BuildContext context) {
    final isIncome = layout == TransactionDetailsLayout.incomeSecondaryOnly;

    return InkWell(
      onTap: onTap,
      borderRadius: expanded
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
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (isIncome ? AppColors.secondary : AppColors.primary)
                    .withAlpha(28),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                isIncome
                    ? Icons.event_note_rounded
                    : Icons.storefront_rounded,
                size: 18,
                color:
                    isIncome ? AppColors.secondary : AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: isIncome
                  ? Text(
                      'Details',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : TextField(
                      controller: merchantController,
                      focusNode: merchantFocus,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Merchant name',
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintStyle: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
            ),
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
    );
  }
}

class _ExpandedBody extends StatelessWidget {
  const _ExpandedBody({
    required this.date,
    required this.onPickDate,
    required this.onQuickDate,
    required this.noteController,
    required this.noteHintText,
  });

  final DateTime date;
  final Future<void> Function() onPickDate;
  final ValueChanged<DateQuickOption> onQuickDate;
  final TextEditingController noteController;
  final String noteHintText;

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
          const _FieldLabel(label: 'Date'),
          const SizedBox(height: AppSpacing.sm),
          _DateQuickRow(date: date, onSelect: onQuickDate, onPick: onPickDate),
          const SizedBox(height: AppSpacing.md),
          const _FieldLabel(label: 'Note'),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: noteController,
            minLines: 1,
            maxLines: 3,
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
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTextStyles.label);
  }
}

class _DateQuickRow extends StatelessWidget {
  const _DateQuickRow({
    required this.date,
    required this.onSelect,
    required this.onPick,
  });

  final DateTime date;
  final ValueChanged<DateQuickOption> onSelect;
  final Future<void> Function() onPick;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final selectedDay = DateTime(date.year, date.month, date.day);
    final isToday = selectedDay == today;
    final isYesterday = selectedDay == yesterday;
    final isCustom = !isToday && !isYesterday;

    return Row(
      children: [
        Expanded(
          child: _QuickDateChip(
            label: 'Today',
            selected: isToday,
            onTap: () => onSelect(DateQuickOption.today),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _QuickDateChip(
            label: 'Yesterday',
            selected: isYesterday,
            onTap: () => onSelect(DateQuickOption.yesterday),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _QuickDateChip(
            label: isCustom ? DateFormat.MMMd().format(date) : 'Pick date',
            icon: Icons.calendar_today_rounded,
            selected: isCustom,
            onTap: onPick,
          ),
        ),
      ],
    );
  }
}

class _QuickDateChip extends StatelessWidget {
  const _QuickDateChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.primary : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.chipRadius,
      child: AnimatedContainer(
        duration: AppDurations.micro,
        curve: AppCurves.spring,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withAlpha(28)
              : AppColors.surfaceSecondary,
          borderRadius: AppRadii.chipRadius,
          border: Border.all(
            color: selected
                ? AppColors.primary.withAlpha(120)
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 6),
            ],
            Flexible(
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
          ],
        ),
      ),
    );
  }
}
