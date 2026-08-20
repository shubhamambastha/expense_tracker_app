import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker_app/models/transaction.dart';
import 'package:expense_tracker_app/models/transaction_draft.dart';

void main() {
  group('Transaction.toMap date serialization', () {
    test('serializes date/closed_at/recurrence fields with explicit UTC', () {
      // Local (non-UTC) DateTimes — DateTime(...) always has isUtc == false,
      // regardless of the test machine's own timezone.
      final localMoment = DateTime(2026, 8, 20, 10, 30);

      final tx = Transaction(
        amount: 15.99,
        counterpartyName: 'Netflix',
        date: localMoment,
        isRecurring: true,
        recurrenceFrequency: RecurrenceFrequency.monthly,
        recurrenceStartDate: localMoment,
        recurrenceEndDate: DateTime(2027, 8, 20, 10, 30),
        closedAt: localMoment,
      );

      final map = tx.toMap();

      // Every serialized timestamp must carry an explicit UTC offset (a
      // trailing 'Z'). Without it, Postgres's timestamptz column
      // interprets the naive digits using its own session timezone
      // (UTC on Supabase) instead of the device's actual local offset —
      // silently shifting the stored instant forward by that offset for
      // any timezone ahead of UTC (e.g. IST, +5:30). That shift is what
      // made upcoming_payments.dart::computeNextPaymentDate's "is this
      // occurrence still upcoming?" check misfire and return the
      // un-advanced start date as "next" instead of stepping forward a
      // full cycle — reported as "renewal date same as start date."
      expect(map['date'], endsWith('Z'));
      expect(map['closed_at'], endsWith('Z'));
      expect(map['recurrence_start_date'], endsWith('Z'));
      expect(map['recurrence_end_date'], endsWith('Z'));
    });

    test('round-trips to the exact same instant regardless of local offset', () {
      final localMoment = DateTime(2026, 8, 20, 10, 30);
      final tx = Transaction(
        amount: 15.99,
        counterpartyName: 'Netflix',
        date: localMoment,
        isRecurring: true,
        recurrenceFrequency: RecurrenceFrequency.monthly,
        recurrenceStartDate: localMoment,
      );

      final map = tx.toMap();
      final roundTripped = DateTime.parse(map['recurrence_start_date'] as String);

      expect(roundTripped.isAtSameMomentAs(localMoment), isTrue);
    });
  });
}
