import 'package:flutter_test/flutter_test.dart';

import 'package:ohana/app/app.dart';

void main() {
  testWidgets('App boots and shows the app name', (tester) async {
    await tester.pumpWidget(const OhanaApp());

    expect(find.text('Ohana'), findsOneWidget);
  });
}
