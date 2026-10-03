import 'package:flutter/material.dart';

class OhanaApp extends StatelessWidget {
  const OhanaApp({super.key});

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
      home: const _PlaceholderHome(),
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
