import 'package:flutter/material.dart';

/// Color tokens. Widgets should read colors from `Theme.of(context).colorScheme`
/// rather than using these directly.
abstract final class AppColors {
  /// Warm terracotta the whole palette is generated from.
  static const seed = Color(0xFFE07A5F);

  static final ColorScheme light = ColorScheme.fromSeed(seedColor: seed);

  static final ColorScheme dark = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
  );
}
