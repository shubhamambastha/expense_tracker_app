import '../models/account.dart';
import '../models/category_budget.dart';
import '../models/transaction.dart';

/// CSV serializers for the Settings "Export Data" flow. Pure functions —
/// no I/O, safe to unit test directly.
///
/// Quotes a CSV field only when it contains a comma, quote, or newline —
/// matches standard CSV (RFC 4180) quoting rules.
String _csvField(Object? value) {
  final text = value?.toString() ?? '';
  if (text.contains(',') || text.contains('"') || text.contains('\n')) {
    return '"${text.replaceAll('"', '""')}"';
  }
  return text;
}

String _csvRow(List<Object?> fields) => fields.map(_csvField).join(',');

String transactionsToCsv(List<Transaction> transactions) {
  final buffer = StringBuffer()
    ..writeln(
      _csvRow([
        'date',
        'kind',
        'amount',
        'currency',
        'category',
        'counterparty',
        'note',
        'is_recurring',
        'recurrence_frequency',
      ]),
    );
  for (final t in transactions) {
    buffer.writeln(
      _csvRow([
        t.date.toIso8601String(),
        t.kind.name,
        t.amount,
        t.currencyCode,
        t.category,
        t.counterpartyName,
        t.note,
        t.isRecurring,
        t.recurrenceFrequency?.name,
      ]),
    );
  }
  return buffer.toString();
}

String accountsToCsv(List<Account> accounts) {
  final buffer = StringBuffer()
    ..writeln(
      _csvRow([
        'name',
        'type',
        'opening_balance',
        'credit_limit',
        'nickname',
        'provider',
      ]),
    );
  for (final a in accounts) {
    buffer.writeln(
      _csvRow([
        a.name,
        a.type.name,
        a.openingBalance,
        a.creditLimit,
        a.nickname,
        a.providerName,
      ]),
    );
  }
  return buffer.toString();
}

String categoryBudgetsToCsv(List<CategoryBudget> budgets) {
  final buffer = StringBuffer()
    ..writeln(_csvRow(['category', 'monthly_limit', 'currency']));
  for (final b in budgets) {
    buffer.writeln(
      _csvRow([b.categoryName, b.monthlyLimit, b.currencyCode]),
    );
  }
  return buffer.toString();
}
