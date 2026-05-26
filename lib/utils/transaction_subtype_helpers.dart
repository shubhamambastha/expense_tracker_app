import '../models/transaction.dart';
import '../models/transaction_draft.dart';
import '../models/transaction_filters.dart';

/// Persisted model:
/// - `kind` → expense | income | transfer
/// - `category` → EMI, Subscription, Refund, Food, …
///
/// Filter chips like EMI / Subscription / Refund are derived from
/// [kind] + [category], not stored as a separate column.
class TransactionSubtypeHelpers {
  TransactionSubtypeHelpers._();

  static const expenseCategoryEmi = 'EMI';
  static const expenseCategorySubscription = 'Subscription';
  static const incomeCategoryRefund = 'Refund';

  /// Quick expense subtypes surfaced on the Add Transaction screen.
  static const expenseSubtypes = [
    expenseCategoryEmi,
    expenseCategorySubscription,
  ];

  static bool isEmiCategory(String? category) =>
      (category ?? '').toLowerCase().contains('emi');

  static bool isSubscriptionCategory(String? category) =>
      (category ?? '').toLowerCase().contains('subscription');

  static bool isRefundCategory(String? category) =>
      (category ?? '').toLowerCase().contains('refund');

  /// Apply an expense quick-pick (EMI / Subscription) to the draft.
  static void applyExpenseSubtype(TransactionDraft draft, String category) {
    draft.kind = TransactionKind.expense;
    draft.categoryName = category;
    draft.recurring = draft.recurring.copyWith(
      enabled: true,
      frequency: RecurrenceFrequency.monthly,
    );
  }

  /// Apply income Refund quick-pick.
  static void applyIncomeRefund(TransactionDraft draft) {
    draft.kind = TransactionKind.income;
    draft.categoryName = incomeCategoryRefund;
  }
}

/// Infer filter/display type — shared by list filters and row badges.
TransactionDisplayType displayTypeForTransaction(Transaction transaction) {
  if (transaction.kind == TransactionKind.transfer) {
    return TransactionDisplayType.transfer;
  }

  final category = transaction.category ?? '';

  if (transaction.kind == TransactionKind.income) {
    if (TransactionSubtypeHelpers.isRefundCategory(category)) {
      return TransactionDisplayType.refund;
    }
    return TransactionDisplayType.income;
  }

  if (TransactionSubtypeHelpers.isEmiCategory(category)) {
    return TransactionDisplayType.emi;
  }
  if (TransactionSubtypeHelpers.isSubscriptionCategory(category) ||
      (transaction.isRecurring &&
          TransactionSubtypeHelpers.isSubscriptionCategory(category))) {
    return TransactionDisplayType.subscription;
  }

  return TransactionDisplayType.expense;
}
