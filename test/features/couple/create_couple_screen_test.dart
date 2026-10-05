import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ohana/features/couple/domain/couple_repository.dart';
import 'package:ohana/features/couple/domain/invite.dart';
import 'package:ohana/features/couple/presentation/couple_providers.dart';
import 'package:ohana/features/couple/presentation/create_couple_screen.dart';

import 'fake_couple_repository.dart';

void main() {
  late FakeCoupleRepository couples;

  Future<void> pumpScreen(WidgetTester tester) async {
    couples = FakeCoupleRepository(
      invite: Invite(
        code: 'V69NX6',
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coupleRepositoryProvider.overrideWithValue(couples),
          deviceTimezoneReaderProvider.overrideWithValue(
            () async => 'Europe/Berlin',
          ),
        ],
        child: const MaterialApp(home: CreateCoupleScreen()),
      ),
    );
  }

  Future<void> tapCreate(WidgetTester tester) async {
    await tester.tap(find.text('Create our space'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'creates the space with the device time zone and shows the code',
    (tester) async {
      await pumpScreen(tester);
      await tapCreate(tester);

      expect(couples.createdWithTimezones, ['Europe/Berlin']);
      expect(find.text('V69NX6'), findsOneWidget);
      expect(find.text('Works once · expires in 7 days'), findsOneWidget);
      expect(find.text('Waiting for your partner to join…'), findsOneWidget);
    },
  );

  testWidgets('copies the code to the clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    await pumpScreen(tester);
    await tapCreate(tester);

    await tester.tap(find.text('Copy code'));
    await tester.pumpAndSettle();

    expect(copied, 'V69NX6');
    expect(find.text('Code copied'), findsOneWidget);

    await tester.tap(find.text('Copy invite link'));
    await tester.pumpAndSettle();

    expect(copied, 'com.ramilsalihar.ohana://invite/join/V69NX6');
  });

  testWidgets('still shows the invite when the space already exists', (
    tester,
  ) async {
    await pumpScreen(tester);
    couples.createCoupleError = const CoupleFailure(
      CoupleFailureReason.alreadyInCouple,
    );
    await tapCreate(tester);

    expect(couples.inviteCalls, 1);
    expect(find.text('V69NX6'), findsOneWidget);
  });

  testWidgets('shows a message when the space is already full', (tester) async {
    await pumpScreen(tester);
    couples.createInviteError = const CoupleFailure(
      CoupleFailureReason.coupleFull,
    );
    await tapCreate(tester);

    expect(find.text('This space already has two people.'), findsOneWidget);
    expect(find.text('V69NX6'), findsNothing);
  });

  testWidgets('unexpected errors show a generic message and allow retry', (
    tester,
  ) async {
    await pumpScreen(tester);
    couples.createCoupleError = StateError('socket closed');
    await tapCreate(tester);

    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('socket'), findsNothing);

    await tapCreate(tester);
    expect(find.text('V69NX6'), findsOneWidget);
  });
}
