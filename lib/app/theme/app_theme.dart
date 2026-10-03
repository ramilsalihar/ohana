import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// App themes built from the design tokens.
abstract final class AppTheme {
  static final ThemeData light = _build(AppColors.light);
  static final ThemeData dark = _build(AppColors.dark);

  static ThemeData _build(ColorScheme colorScheme) {
    return ThemeData(
      colorScheme: colorScheme,
      textTheme: AppTypography.textTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
    );
  }
}
