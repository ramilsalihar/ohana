import 'package:flutter/material.dart';

class OhanaApp extends StatelessWidget {
  const OhanaApp({super.key, this.missingEnv = const []});

  /// Names of required environment values that were not provided at build
  /// time. When non-empty the app shows a setup message instead of the UI.
  final List<String> missingEnv;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ohana',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE07A5F)),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE07A5F),
          brightness: Brightness.dark,
        ),
      ),
      home: missingEnv.isEmpty
          ? const _PlaceholderHome()
          : _MissingConfigScreen(missing: missingEnv),
    );
  }
}

class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ohana', style: textTheme.displaySmall),
            const SizedBox(height: 8),
            Text('Daily rituals for couples', style: textTheme.bodyLarge),
          ],
        ),
      ),
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
