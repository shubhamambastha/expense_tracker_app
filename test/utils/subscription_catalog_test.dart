import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker_app/utils/subscription_catalog.dart';

void main() {
  group('SubscriptionCatalog.forName', () {
    test('exact match, case variants all resolve to the same entry', () {
      final lower = SubscriptionCatalog.forName('netflix');
      final upper = SubscriptionCatalog.forName('NETFLIX');
      final mixed = SubscriptionCatalog.forName('Netflix');
      expect(lower, isNotNull);
      expect(lower!.name, 'Netflix');
      expect(upper?.name, 'Netflix');
      expect(mixed?.name, 'Netflix');
    });

    test('no match returns null', () {
      expect(SubscriptionCatalog.forName('My Local Gym'), isNull);
    });

    test('null or empty input returns null', () {
      expect(SubscriptionCatalog.forName(null), isNull);
      expect(SubscriptionCatalog.forName(''), isNull);
      expect(SubscriptionCatalog.forName('   '), isNull);
    });

    test('superset text does not match (exact, not substring)', () {
      expect(SubscriptionCatalog.forName('Netflix Gift Card'), isNull);
      expect(SubscriptionCatalog.forName('My Netflix'), isNull);
    });

    test('surrounding whitespace is trimmed before matching', () {
      expect(SubscriptionCatalog.forName('  Netflix  ')?.name, 'Netflix');
    });

    test('catalog has no duplicate names (case-insensitive)', () {
      final seen = <String>{};
      for (final entry in SubscriptionCatalog.entries) {
        final key = entry.name.toLowerCase();
        expect(
          seen.add(key),
          isTrue,
          reason: '${entry.name} is a duplicate catalog entry',
        );
      }
    });
  });
}
