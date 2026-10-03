import 'package:flutter_test/flutter_test.dart';

import 'package:ohana/app/app.dart';

void main() {
  testWidgets('App boots and shows the app name', (tester) async {
    await tester.pumpWidget(const OhanaApp());

    expect(find.text('Ohana'), findsOneWidget);
  });

  testWidgets('App boots with a clear message when env values are missing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const OhanaApp(missingEnv: ['SUPABASE_URL', 'SUPABASE_ANON_KEY']),
    );

    expect(find.text('Ohana is not configured'), findsOneWidget);
    expect(
      find.text('Missing: SUPABASE_URL, SUPABASE_ANON_KEY'),
      findsOneWidget,
    );
  });
}
