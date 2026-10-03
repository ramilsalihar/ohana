import 'package:flutter/material.dart';

/// Typography scale. Sizes are logical pixels and scale with the user's
/// text size setting; `height` is the line-height multiplier.
abstract final class AppTypography {
  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 48,
      height: 1.15,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
    ),
    displayMedium: TextStyle(
      fontSize: 40,
      height: 1.15,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.25,
    ),
    displaySmall: TextStyle(
      fontSize: 34,
      height: 1.2,
      fontWeight: FontWeight.w600,
    ),
    headlineLarge: TextStyle(
      fontSize: 30,
      height: 1.25,
      fontWeight: FontWeight.w600,
    ),
    headlineMedium: TextStyle(
      fontSize: 26,
      height: 1.25,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: TextStyle(
      fontSize: 22,
      height: 1.3,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      height: 1.3,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      fontSize: 17,
      height: 1.35,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: TextStyle(
      fontSize: 15,
      height: 1.35,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(
      fontSize: 17,
      height: 1.5,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: TextStyle(
      fontSize: 15,
      height: 1.45,
      fontWeight: FontWeight.w400,
    ),
    bodySmall: TextStyle(
      fontSize: 13,
      height: 1.4,
      fontWeight: FontWeight.w400,
    ),
    labelLarge: TextStyle(
      fontSize: 15,
      height: 1.3,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontSize: 13,
      height: 1.3,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      height: 1.3,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  );
}
