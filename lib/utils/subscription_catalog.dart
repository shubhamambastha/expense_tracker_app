import 'package:flutter/material.dart';

/// One curated subscription: matched against [Transaction.counterpartyName]
/// to pick a brand-colored badge instead of the generic category icon.
///
/// [color] is a placeholder brand-color mark, not a traced logo — see
/// TODOS.md for the legal check before real logos ever replace these.
class SubscriptionEntry {
  const SubscriptionEntry({required this.name, required this.color});

  final String name;
  final Color color;
}

/// Curated, fixed const list of common subscriptions — same "static catalog"
/// shape as [DefaultCategories.seeds] in category_style.dart, not a
/// user-editable table.
class SubscriptionCatalog {
  SubscriptionCatalog._();

  static const List<SubscriptionEntry> entries = [
    SubscriptionEntry(name: 'Netflix', color: Color(0xFFE50914)),
    SubscriptionEntry(name: 'Spotify', color: Color(0xFF1DB954)),
    SubscriptionEntry(name: 'Amazon Prime', color: Color(0xFF00A8E1)),
    SubscriptionEntry(name: 'Disney+', color: Color(0xFF113CCF)),
    SubscriptionEntry(name: 'YouTube Premium', color: Color(0xFFFF0000)),
    SubscriptionEntry(name: 'Apple Music', color: Color(0xFFFA243C)),
    SubscriptionEntry(name: 'Apple TV+', color: Color(0xFF4A4A4F)),
    SubscriptionEntry(name: 'Max', color: Color(0xFF5822B4)),
    SubscriptionEntry(name: 'Hulu', color: Color(0xFF1CE783)),
    SubscriptionEntry(name: 'Peacock', color: Color(0xFF000000)),
    SubscriptionEntry(name: 'Paramount+', color: Color(0xFF0064FF)),
    SubscriptionEntry(name: 'iCloud+', color: Color(0xFF3693F3)),
    SubscriptionEntry(name: 'Google One', color: Color(0xFF4285F4)),
    SubscriptionEntry(name: 'Microsoft 365', color: Color(0xFFD83B01)),
    SubscriptionEntry(name: 'Adobe Creative Cloud', color: Color(0xFFDA1F26)),
    SubscriptionEntry(name: 'PlayStation Plus', color: Color(0xFF003791)),
    SubscriptionEntry(name: 'Xbox Game Pass', color: Color(0xFF107C10)),
    SubscriptionEntry(name: 'Notion', color: Color(0xFF37352F)),
    SubscriptionEntry(name: 'ChatGPT Plus', color: Color(0xFF10A37F)),
    SubscriptionEntry(name: 'Dropbox', color: Color(0xFF0061FF)),
    SubscriptionEntry(name: 'Audible', color: Color(0xFFF8991D)),
    SubscriptionEntry(name: 'Canva', color: Color(0xFF00C4CC)),
    SubscriptionEntry(name: 'Duolingo', color: Color(0xFF58CC02)),
  ];

  static final Map<String, SubscriptionEntry> _byName = {
    for (final e in entries) e.name.toLowerCase(): e,
  };

  /// Exact, case-insensitive match only — NOT substring. "Netflix Gift Card"
  /// must not match "Netflix"; a false-positive brand icon is worse than the
  /// generic category-icon fallback every unmatched merchant already gets.
  static SubscriptionEntry? forName(String? merchantName) {
    final trimmed = merchantName?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return _byName[trimmed.toLowerCase()];
  }
}
