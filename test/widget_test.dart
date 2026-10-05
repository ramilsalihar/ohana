import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ohana/app/app.dart';
import 'package:ohana/features/auth/presentation/auth_providers.dart';

import 'features/auth/fake_auth_repository.dart';

void main() {
  testWidgets('App boots and shows the app name', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: const OhanaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ohana'), findsOneWidget);
  });

  testWidgets('App boots with a clear message when env values are missing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: OhanaApp(missingEnv: ['SUPABASE_URL', 'SUPABASE_ANON_KEY']),
      ),
    );

    expect(find.text('Ohana is not configured'), findsOneWidget);
    expect(
      find.text('Missing: SUPABASE_URL, SUPABASE_ANON_KEY'),
      findsOneWidget,
    );
  });
}
