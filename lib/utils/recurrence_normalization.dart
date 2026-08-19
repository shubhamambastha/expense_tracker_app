import '../models/transaction.dart';
import '../models/transaction_draft.dart';

/// Normalises a recurring transaction's amount to a per-month figure.
///
/// Previously duplicated in `recurring_management.dart`, `analytics_aggregations.dart`,
/// and `financial_insights.dart` — extracted so every screen agrees on the
/// same weekly/daily/quarterly/yearly conversion.
double monthlyEquivalent(Transaction transaction) {
  switch (transaction.recurrenceFrequency) {
    case RecurrenceFrequency.weekly:
      return transaction.amount * 4.33;
    case RecurrenceFrequency.daily:
      return transaction.amount * 30;
    case RecurrenceFrequency.quarterly:
      return transaction.amount / 3;
    case RecurrenceFrequency.yearly:
      return transaction.amount / 12;
    case RecurrenceFrequency.monthly:
    case RecurrenceFrequency.custom:
    case null:
      return transaction.amount;
  }
}
