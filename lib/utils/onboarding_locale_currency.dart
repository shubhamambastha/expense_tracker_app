import 'dart:ui';

import '../services/currency_settings.dart';

/// Maps a device locale's country code to one of [CurrencySettings.supported].
/// Falls back to USD when the locale doesn't map to a supported currency
/// (Section 4 edge case) — never blank, never a crash.
String currencyCodeForLocale(Locale locale) {
  final country = locale.countryCode;
  if (country == null) return CurrencySettings.defaultCode;
  final code = _countryToCurrency[country];
  if (code == null || !CurrencySettings.isSupportedCode(code)) {
    return CurrencySettings.defaultCode;
  }
  return code;
}

const _countryToCurrency = <String, String>{
  'US': 'USD',
  'DE': 'EUR', 'FR': 'EUR', 'ES': 'EUR', 'IT': 'EUR', 'NL': 'EUR',
  'GB': 'GBP',
  'IN': 'INR',
  'CA': 'CAD',
  'AU': 'AUD',
  'JP': 'JPY',
  'CH': 'CHF',
  'SG': 'SGD',
  'AE': 'AED',
};
