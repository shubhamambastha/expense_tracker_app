import 'package:flutter/material.dart';

/// User-selectable brand accent (drives [AppColors.primary]).
enum AppAccent { teal, blue, purple }

extension AppAccentStyle on AppAccent {
  String get label {
    switch (this) {
      case AppAccent.teal:
        return 'Teal';
      case AppAccent.blue:
        return 'Blue';
      case AppAccent.purple:
        return 'Purple';
    }
  }

  Color get color {
    switch (this) {
      case AppAccent.teal:
        return const Color(0xFF00C896);
      case AppAccent.blue:
        return const Color(0xFF0A84FF);
      case AppAccent.purple:
        return const Color(0xFFAF52DE);
    }
  }
}

/// Centralised iOS-native design tokens.
///
/// Source of truth for colors, radii, shadows, durations, and typography
/// across the app. Update values here to roll a new look everywhere.
///
/// Colors resolve dynamically off [configure] (brightness + accent) rather
/// than being fixed `const` values, so every existing `AppColors.xxx`
/// call site picks up theme changes automatically without being rewritten.
/// ponytail: global mutable brightness/accent flags instead of a
/// ThemeExtension/InheritedWidget — fine while the app never shows two
/// themes at once; revisit if that ever changes.
class AppColors {
  AppColors._();

  static Brightness _brightness = Brightness.dark;
  static AppAccent _accent = AppAccent.teal;

  static bool get _isDark => _brightness == Brightness.dark;

  /// Currently configured brightness (read-only).
  static Brightness get brightness => _brightness;

  /// Currently configured accent (read-only).
  static AppAccent get accent => _accent;

  /// Applies the active theme. Called once per rebuild from `main.dart`
  /// before `MaterialApp` is built.
  static void configure({
    required Brightness brightness,
    required AppAccent accent,
  }) {
    _brightness = brightness;
    _accent = accent;
  }

  // Surfaces
  static Color get background =>
      _isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
  static Color get surface =>
      _isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);
  static Color get surfaceSecondary =>
      _isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);

  // Accents
  static Color get primary => _accent.color;
  static const secondary = Color(0xFF0A84FF);

  // Text
  static Color get textPrimary =>
      _isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
  static Color get textSecondary =>
      _isDark ? const Color(0x99EBEBF5) : const Color(0x993C3C43);
  static Color get textTertiary =>
      _isDark ? const Color(0x4DEBEBF5) : const Color(0x593C3C43);

  // Lines
  static Color get border =>
      _isDark ? const Color(0x8C545458) : const Color(0x1F3C3C43);
  static Color get divider => border;

  // Semantic (true iOS system colors — constant across brightness/accent)
  static const danger = Color(0xFFFF3B30);
  static const warning = Color(0xFFFF9500);
  static const success = Color(0xFF34C759);

  /// Foreground for content drawn on top of [primary]-filled surfaces.
  /// White reads cleanly across all three accent hues, so this doesn't
  /// need to vary like the old per-accent dark literals did.
  static const onPrimary = Color(0xFFFFFFFF);

  /// Dark foreground for content drawn on flat [primary] fills or the
  /// primary→secondary gradient (e.g. the sticky save CTA, the avatar
  /// camera badge) — kept distinct from [onPrimary] because these small,
  /// icon-scale accents read better with a dark mark than white.
  static const onAccent = Color(0xFF003328);

  // Container tints (subtle accent-tinted fills, derived so they follow
  // the active accent/brightness instead of being hand-picked hex values)
  static Color get primarySoft => Color.alphaBlend(primary.withAlpha(46), surface);
  static Color get secondarySoft =>
      Color.alphaBlend(secondary.withAlpha(46), surface);
  static Color get dangerSoft => Color.alphaBlend(danger.withAlpha(46), surface);
  static Color get warningSoft =>
      Color.alphaBlend(warning.withAlpha(46), surface);
}

class AppRadii {
  AppRadii._();

  static const double card = 20.0;
  static const double button = 16.0;
  static const double input = 18.0;
  static const double pill = 999.0;
  static const double chip = 12.0;

  static const cardRadius = BorderRadius.all(Radius.circular(card));
  static const buttonRadius = BorderRadius.all(Radius.circular(button));
  static const inputRadius = BorderRadius.all(Radius.circular(input));
  static const pillRadius = BorderRadius.all(Radius.circular(pill));
  static const chipRadius = BorderRadius.all(Radius.circular(chip));

  /// iOS-style continuous (superellipse) corner shapes — prefer these over
  /// hand-rolled `RoundedRectangleBorder`s for Material `shape:` params so
  /// corners match native UIKit/SwiftUI curvature instead of a true arc.
  static const OutlinedBorder cardBorder =
      ContinuousRectangleBorder(borderRadius: cardRadius);
  static const OutlinedBorder buttonBorder =
      ContinuousRectangleBorder(borderRadius: buttonRadius);
  static const OutlinedBorder inputBorder =
      ContinuousRectangleBorder(borderRadius: inputRadius);
  static const OutlinedBorder pillBorder =
      ContinuousRectangleBorder(borderRadius: pillRadius);
  static const OutlinedBorder chipBorder =
      ContinuousRectangleBorder(borderRadius: chipRadius);
}

class AppShadows {
  AppShadows._();

  /// Default very-subtle card shadow.
  static const card = <BoxShadow>[
    BoxShadow(
      color: Color(0x2E000000),
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
  ];

  static const elevated = <BoxShadow>[
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 28,
      offset: Offset(0, 12),
    ),
  ];

  static const subtle = <BoxShadow>[
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 12,
      offset: Offset(0, 2),
    ),
  ];
}

class AppDurations {
  AppDurations._();

  /// Micro interactions: hover, tap, toggle.
  static const Duration micro = Duration(milliseconds: 180);
  static const Duration short = Duration(milliseconds: 220);

  /// Page transitions and surface swaps.
  static const Duration page = Duration(milliseconds: 280);
  static const Duration pageLong = Duration(milliseconds: 350);

  /// Decorative reveal animations (charts, lists).
  static const Duration reveal = Duration(milliseconds: 600);
}

class AppCurves {
  AppCurves._();

  /// Spring-feel curve for premium micro-interactions.
  static const Cubic spring = Cubic(0.2, 0.9, 0.25, 1.0);
  static const Cubic easeOutQuint = Cubic(0.23, 1, 0.32, 1);
  static const Cubic emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

/// SF Pro-aligned typography scale (iOS system font).
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = '.SF Pro Text';
  static const List<String> _fallback = ['Helvetica Neue'];

  static TextStyle get displayLarge => TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: _fallback,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    height: 1.05,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static TextStyle get displayMedium => TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: _fallback,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.08,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
  );

  static TextStyle get displaySmall => TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: _fallback,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  static TextStyle get headingLarge => TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: _fallback,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  static TextStyle get headingMedium => TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: _fallback,
    fontSize: 19,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  static TextStyle get headingSmall => TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: _fallback,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyLarge => TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: _fallback,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: _fallback,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.45,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodySmall => TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: _fallback,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.textSecondary,
  );

  static TextStyle get caption => TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: _fallback,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  static TextStyle get label => TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: _fallback,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.2,
    color: AppColors.textSecondary,
  );

  static TextStyle get button => TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: _fallback,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.1,
  );
}
