import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';

/// Placeholder welcome screen until onboarding is built.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Get started'),
            ),
          ],
        ),
      ),
    );
  }
}
