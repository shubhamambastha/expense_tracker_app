import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../models/transaction.dart';
import '../../models/transaction_draft.dart' show RecurrenceFrequencyX;
import '../../services/currency_settings.dart';
import '../../utils/recurring_management.dart';
import '../../utils/transaction_subtype_helpers.dart';
import '../recurring/add_recurring_sheet.dart';
import 'onboarding_step_scaffold.dart';

/// Step 6/6 — recurring expenses/subscriptions. Lists the 3 kinds directly
/// on this step (reusing [RecurringKindRow], the same row `showAddRecurringSheet`
/// uses elsewhere) instead of opening a picker sheet first — one tap
/// straight into `AddTransactionPage`, no extra layer. Also lists what's
/// already been added this session above the kind rows, so the user can
/// see what's covered vs. what still needs adding instead of having to
/// remember or guess.
class OnboardingRecurringIntroStep extends StatelessWidget {
  const OnboardingRecurringIntroStep({
    super.key,
    required this.items,
    required this.onSkip,
    required this.onPickKind,
    this.onBack,
  });

  final List<Transaction> items;
  final VoidCallback onSkip;
  final ValueChanged<RecurringKind> onPickKind;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      heading: 'Any recurring expenses?',
      subtext: 'Pick a kind — add as many as you like, then Skip when done.',
      onSkip: onSkip,
      onNext: onSkip,
      onBack: onBack,
      nextLabel: 'Done',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (items.isNotEmpty) ...[
            Text('Added', style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            )),
            const SizedBox(height: AppSpacing.sm),
            for (final item in items) ...[
              _AddedItemRow(transaction: item),
              const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.sm),
          ],
          RecurringKindRow(
            icon: Icons.subscriptions_rounded,
            tone: AppColors.secondary,
            title: 'Add Subscription',
            subtitle: 'Netflix, Spotify, ChatGPT — monthly digital services.',
            onTap: () => onPickKind(RecurringKind.subscription),
          ),
          const SizedBox(height: AppSpacing.sm),
          RecurringKindRow(
            icon: Icons.receipt_long_rounded,
            tone: AppColors.warning,
            title: 'Add EMI',
            subtitle: 'Home, car, gadget, credit-card EMIs with a tenure.',
            onTap: () => onPickKind(RecurringKind.emi),
          ),
          const SizedBox(height: AppSpacing.sm),
          RecurringKindRow(
            icon: Icons.autorenew_rounded,
            tone: AppColors.primary,
            title: 'Add Recurring Expense',
            subtitle: 'Rent, electricity, internet, insurance, SIPs.',
            onTap: () => onPickKind(RecurringKind.other),
          ),
        ],
      ),
    );
  }
}

class _AddedItemRow extends StatelessWidget {
  const _AddedItemRow({required this.transaction});

  final Transaction transaction;

  static const _icons = {
    _RowKind.subscription: Icons.subscriptions_rounded,
    _RowKind.emi: Icons.receipt_long_rounded,
    _RowKind.other: Icons.autorenew_rounded,
  };

  _RowKind get _kind {
    if (TransactionSubtypeHelpers.isSubscriptionCategory(
      transaction.category,
    )) {
      return _RowKind.subscription;
    }
    if (TransactionSubtypeHelpers.isEmiCategory(transaction.category)) {
      return _RowKind.emi;
    }
    return _RowKind.other;
  }

  @override
  Widget build(BuildContext context) {
    final currency = CurrencySettings.instance;
    final frequency = transaction.recurrenceFrequency?.label;
    final detail = frequency == null
        ? currency.format(transaction.amount)
        : '${currency.format(transaction.amount)} · $frequency';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(_icons[_kind], color: AppColors.textPrimary, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                transaction.counterpartyName,
                style: AppTextStyles.bodyLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              detail,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _RowKind { subscription, emi, other }
