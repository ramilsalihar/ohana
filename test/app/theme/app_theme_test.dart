import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ohana/app/theme/app_colors.dart';
import 'package:ohana/app/theme/app_spacing.dart';
import 'package:ohana/app/theme/app_theme.dart';
import 'package:ohana/app/theme/app_typography.dart';

/// WCAG 2.1 contrast ratio between two opaque colors.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('light and dark themes use the matching color schemes', () {
    expect(AppTheme.light.colorScheme, AppColors.light);
    expect(AppTheme.dark.colorScheme, AppColors.dark);
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
  });

  test('text and primary color pairs meet WCAG AA contrast', () {
    for (final scheme in [AppColors.light, AppColors.dark]) {
      final pairs = {
        'onSurface/surface': (scheme.onSurface, scheme.surface),
        'onSurfaceVariant/surface': (scheme.onSurfaceVariant, scheme.surface),
        'onPrimary/primary': (scheme.onPrimary, scheme.primary),
        'onPrimaryContainer/primaryContainer': (
          scheme.onPrimaryContainer,
          scheme.primaryContainer,
        ),
        'onError/error': (scheme.onError, scheme.error),
      };
      pairs.forEach((name, pair) {
        expect(
          contrast(pair.$1, pair.$2),
          greaterThanOrEqualTo(4.5),
          reason: '$name in ${scheme.brightness.name}',
        );
      });
    }
  });

  test('themes apply the typography scale', () {
    final body = AppTheme.light.textTheme.bodyLarge!;
    expect(body.fontSize, AppTypography.textTheme.bodyLarge!.fontSize);
    expect(body.color, AppColors.light.onSurface);
  });

  test('typography scale shrinks within each group', () {
    const t = AppTypography.textTheme;
    final groups = [
      [t.displayLarge, t.displayMedium, t.displaySmall],
      [t.headlineLarge, t.headlineMedium, t.headlineSmall],
      [t.titleLarge, t.titleMedium, t.titleSmall],
      [t.bodyLarge, t.bodyMedium, t.bodySmall],
      [t.labelLarge, t.labelMedium, t.labelSmall],
    ];
    for (final group in groups) {
      final sizes = group.map((s) => s!.fontSize!).toList();
      expect(sizes[0], greaterThan(sizes[1]));
      expect(sizes[1], greaterThan(sizes[2]));
    }
  });

  test('spacing scale is strictly increasing', () {
    const scale = [
      AppSpacing.xxs,
      AppSpacing.xs,
      AppSpacing.sm,
      AppSpacing.md,
      AppSpacing.lg,
      AppSpacing.xl,
      AppSpacing.xxl,
      AppSpacing.xxxl,
    ];
    for (var i = 1; i < scale.length; i++) {
      expect(scale[i], greaterThan(scale[i - 1]));
    }
  });
}
