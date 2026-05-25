import 'package:flutter/material.dart';

/// Centralised premium dark-theme design tokens.
///
/// Source of truth for colors, radii, shadows, durations, and typography
/// across the app. Update values here to roll a new look everywhere.
class AppColors {
  AppColors._();

  // Surfaces
  static const background = Color(0xFF0F1115);
  static const surface = Color(0xFF171A21);
  static const surfaceSecondary = Color(0xFF1E232D);

  // Accents
  static const primary = Color(0xFF00C896);
  static const secondary = Color(0xFF00B8D9);

  // Text
  static const textPrimary = Color(0xFFF5F7FA);
  static const textSecondary = Color(0xFFA8B0BF);

  // Lines
  static const border = Color(0xFF262C36);
  static const divider = Color(0xFF262C36);

  // Semantic
  static const danger = Color(0xFFFF5C7A);
  static const warning = Color(0xFFFFB547);
  static const success = Color(0xFF00C896);

  // Container tints (subtle accent-tinted fills)
  static const primarySoft = Color(0xFF002820);
  static const secondarySoft = Color(0xFF002632);
  static const dangerSoft = Color(0xFF351720);
  static const warningSoft = Color(0xFF3A2A12);
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

/// Inter typography scale aligned to the design spec.
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Inter';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.05,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.08,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle headingLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle headingMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  static const TextStyle headingSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.45,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.2,
    color: AppColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.1,
  );
}
