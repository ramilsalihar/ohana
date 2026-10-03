import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';

class OhanaApp extends ConsumerWidget {
  const OhanaApp({super.key, this.missingEnv = const []});

  /// Names of required environment values that were not provided at build
  /// time. When non-empty the app shows a setup message instead of the UI.
  final List<String> missingEnv;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const seedColor = Color(0xFFE07A5F);
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
    );
    final darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
    );

    if (missingEnv.isNotEmpty) {
      return MaterialApp(
        title: 'Ohana',
        debugShowCheckedModeBanner: false,
        theme: theme,
        darkTheme: darkTheme,
        home: _MissingConfigScreen(missing: missingEnv),
      );
    }

    return MaterialApp.router(
      title: 'Ohana',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: darkTheme,
      routerConfig: ref.watch(routerProvider),
    );
  }
}

class _MissingConfigScreen extends StatelessWidget {
  const _MissingConfigScreen({required this.missing});

  final List<String> missing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Ohana is not configured', style: textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text(
                  'Missing: ${missing.join(', ')}',
                  style: textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Copy .env.example to .env, fill in the values, then run '
                  'with --dart-define-from-file=.env',
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
