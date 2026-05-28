/// Per-occurrence action recorded for a recurring transaction.
///
/// One row in `public.recurring_events`. Captures the moment the user
/// interacted with a *specific* scheduled occurrence of an `isRecurring`
/// transaction (e.g. "I paid Netflix's May 1 charge", "skip June 1's gym
/// EMI", "snooze the internet bill by 3 days").
///
/// The Recurring Payments Manager reads these alongside the recurring
/// transactions to compute the next *real* due date — see
/// `lib/utils/recurring_management.dart`.
enum RecurringEventType { paid, skipped, snoozed }

extension RecurringEventTypeX on RecurringEventType {
  String get label {
    switch (this) {
      case RecurringEventType.paid:
        return 'Paid';
      case RecurringEventType.skipped:
        return 'Skipped';
      case RecurringEventType.snoozed:
        return 'Snoozed';
    }
  }
}

class RecurringEvent {
  const RecurringEvent({
    this.id,
    this.userId,
    required this.transactionId,
    required this.occurrenceDate,
    required this.eventType,
    this.snoozeUntil,
    this.createdAt,
  });

  final int? id;
  final String? userId;
  final int transactionId;

  /// The scheduled due date this event is about — always treated as a
  /// calendar date (no time component) so it matches the SQL `date` column.
  final DateTime occurrenceDate;

  final RecurringEventType eventType;

  /// Only meaningful for [RecurringEventType.snoozed]; the new due date the
  /// user wants to be reminded on.
  final DateTime? snoozeUntil;

  final DateTime? createdAt;

  factory RecurringEvent.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic raw) {
      if (raw == null) return null;
      return DateTime.tryParse(raw.toString());
    }

    final typeRaw = map['event_type'] as String? ?? 'paid';
    final eventType = RecurringEventType.values.firstWhere(
      (t) => t.name == typeRaw,
      orElse: () => RecurringEventType.paid,
    );

    return RecurringEvent(
      id: map['id'] is int
          ? map['id'] as int
          : int.tryParse(map['id']?.toString() ?? ''),
      userId: map['user_id'] as String?,
      transactionId: map['transaction_id'] is int
          ? map['transaction_id'] as int
          : int.tryParse(map['transaction_id']?.toString() ?? '') ?? 0,
      occurrenceDate: parseDate(map['occurrence_date']) ?? DateTime.now(),
      eventType: eventType,
      snoozeUntil: parseDate(map['snooze_until']),
      createdAt: parseDate(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'transaction_id': transactionId,
      'occurrence_date': _dateOnly(occurrenceDate),
      'event_type': eventType.name,
      if (snoozeUntil != null) 'snooze_until': _dateOnly(snoozeUntil!),
    };
  }

  RecurringEvent copyWith({
    int? id,
    String? userId,
    int? transactionId,
    DateTime? occurrenceDate,
    RecurringEventType? eventType,
    DateTime? snoozeUntil,
    bool clearSnoozeUntil = false,
    DateTime? createdAt,
  }) {
    return RecurringEvent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      transactionId: transactionId ?? this.transactionId,
      occurrenceDate: occurrenceDate ?? this.occurrenceDate,
      eventType: eventType ?? this.eventType,
      snoozeUntil:
          clearSnoozeUntil ? null : (snoozeUntil ?? this.snoozeUntil),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Serialise a [DateTime] as a calendar-only `YYYY-MM-DD` string so it lines
  /// up with the SQL `date` column (no tz conversion).
  static String _dateOnly(DateTime when) {
    final y = when.year.toString().padLeft(4, '0');
    final m = when.month.toString().padLeft(2, '0');
    final d = when.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
