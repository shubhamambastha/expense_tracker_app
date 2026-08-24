import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/transaction_draft.dart';
import '../../utils/recurring_management.dart';
import '../../utils/transaction_subtype_helpers.dart';

/// Three-option add menu surfaced from the manager screen's floating "+".
///
/// Each row maps to a [RecurringKind]; the caller turns the choice into a
/// preconfigured [TransactionDraft] via [applyDraftFor] and pushes the
/// existing AddTransactionPage.
Future<RecurringKind?> showAddRecurringSheet(BuildContext context) {
  return showModalBottomSheet<RecurringKind>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  'Add Recurring Payment',
                  style: AppTextStyles.headingSmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Text(
                  'Pick a kind and we\'ll preconfigure the schedule for you.',
                  style: AppTextStyles.bodySmall,
                ),
              ),
              RecurringKindRow(
                icon: Icons.subscriptions_rounded,
                tone: AppColors.secondary,
                title: 'Add Subscription',
                subtitle:
                    'Netflix, Spotify, ChatGPT — monthly digital services.',
                onTap: () =>
                    Navigator.of(sheetContext).pop(RecurringKind.subscription),
              ),
              const SizedBox(height: AppSpacing.sm),
              RecurringKindRow(
                icon: Icons.receipt_long_rounded,
                tone: AppColors.warning,
                title: 'Add EMI',
                subtitle:
                    'Home, car, gadget, credit-card EMIs with a tenure.',
                onTap: () =>
                    Navigator.of(sheetContext).pop(RecurringKind.emi),
              ),
              const SizedBox(height: AppSpacing.sm),
              RecurringKindRow(
                icon: Icons.autorenew_rounded,
                tone: AppColors.primary,
                title: 'Add Recurring Expense',
                subtitle: 'Rent, electricity, internet, insurance, SIPs.',
                onTap: () =>
                    Navigator.of(sheetContext).pop(RecurringKind.other),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Mutates [draft] so the Add Transaction screen opens with the right
/// recurring-template state for the chosen [kind].
void applyDraftFor(TransactionDraft draft, RecurringKind kind) {
  switch (kind) {
    case RecurringKind.subscription:
      TransactionSubtypeHelpers.applyExpenseSubtype(
        draft,
        TransactionSubtypeHelpers.expenseCategorySubscription,
      );
      break;
    case RecurringKind.emi:
      TransactionSubtypeHelpers.applyExpenseSubtype(
        draft,
        TransactionSubtypeHelpers.expenseCategoryEmi,
      );
      break;
    case RecurringKind.other:
      draft.kind = TransactionKind.expense;
      draft.recurring = draft.recurring.copyWith(
        enabled: true,
        frequency: RecurrenceFrequency.monthly,
      );
      break;
  }
}

class RecurringKindRow extends StatelessWidget {
  const RecurringKindRow({
    super.key,
    required this.icon,
    required this.tone,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color tone;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.cardRadius,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: AppRadii.cardRadius,
            border: Border.all(color: tone.withAlpha(60)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tone.withAlpha(36),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: tone, size: 22),
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
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
