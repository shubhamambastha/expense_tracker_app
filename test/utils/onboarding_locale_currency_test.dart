import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker_app/utils/onboarding_locale_currency.dart';

void main() {
  group('currencyCodeForLocale', () {
    test('maps a known country code to its currency', () {
      expect(currencyCodeForLocale(const Locale('en', 'IN')), 'INR');
      expect(currencyCodeForLocale(const Locale('en', 'GB')), 'GBP');
      expect(currencyCodeForLocale(const Locale('ja', 'JP')), 'JPY');
    });

    test('falls back to USD for an unmapped country code', () {
      expect(currencyCodeForLocale(const Locale('xx', 'ZZ')), 'USD');
    });

    test('falls back to USD when the locale has no country code', () {
      expect(currencyCodeForLocale(const Locale('en')), 'USD');
    });
  });
}
