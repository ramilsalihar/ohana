import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:ohana/features/couple/domain/couple_repository.dart';
import 'package:ohana/features/couple/domain/invite.dart';
import 'package:ohana/features/couple/presentation/couple_providers.dart';
import 'package:ohana/features/profile/domain/profile.dart';
import 'package:ohana/features/profile/domain/profile_repository.dart';
import 'package:ohana/features/profile/presentation/profile_providers.dart';
import 'package:ohana/features/profile/presentation/profile_setup_screen.dart';

import '../couple/fake_couple_repository.dart';
import 'fake_profile_repository.dart';

/// A valid 1x1 PNG, so the picked avatar can actually be decoded.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

void main() {
  late FakeProfileRepository profiles;
  late FakeCoupleRepository couples;
  AvatarImage? nextPick;

  Future<void> pumpScreen(
    WidgetTester tester, {
    Profile? profile,
    CoupleSpace? couple,
    Object? loadError,
  }) async {
    profiles = FakeProfileRepository(profile: profile)..loadError = loadError;
    couples = FakeCoupleRepository(
      invite: Invite(code: 'UNUSED', expiresAt: DateTime(2030)),
    )..couple = couple;
    nextPick = null;
    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (_, _) => const ProfileSetupScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('HOME')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(profiles),
          coupleRepositoryProvider.overrideWithValue(couples),
          avatarPickerProvider.overrideWithValue(() async => nextPick),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
  }

  testWidgets('saves a new display name and leaves the screen', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextFormField), '  Sam  ');
    await save(tester);

    expect(profiles.saves.single.displayName, 'Sam');
    expect(profiles.saves.single.newAvatar, isNull);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('shows the existing name', (tester) async {
    await pumpScreen(
      tester,
      profile: const Profile(id: 'u1', displayName: 'Sam'),
    );

    expect(find.text('Sam'), findsOneWidget);
  });

  testWidgets('requires a name', (tester) async {
    await pumpScreen(tester);
    await save(tester);

    expect(profiles.saves, isEmpty);
    expect(find.text('Enter your name'), findsOneWidget);
  });

  testWidgets('uploads a picked photo with the profile', (tester) async {
    await pumpScreen(tester);
    nextPick = AvatarImage(bytes: _png, contentType: 'image/png');

    await tester.tap(find.text('Add a photo'));
    await tester.pumpAndSettle();
    expect(find.text('Change photo'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Sam');
    await save(tester);

    expect(profiles.saves.single.newAvatar?.contentType, 'image/png');
  });

  testWidgets('rejects unsupported and oversized photos before upload', (
    tester,
  ) async {
    await pumpScreen(tester);

    nextPick = AvatarImage(bytes: _png, contentType: 'image/gif');
    await tester.tap(find.text('Add a photo'));
    await tester.pumpAndSettle();
    expect(find.text('Use a JPEG, PNG or WebP image.'), findsOneWidget);

    nextPick = AvatarImage(
      bytes: Uint8List(AvatarImage.maxBytes + 1),
      contentType: 'image/jpeg',
    );
    await tester.tap(find.text('Add a photo'));
    await tester.pumpAndSettle();
    expect(find.text('That image is too large (2 MB max).'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Sam');
    await save(tester);
    expect(profiles.saves.single.newAvatar, isNull);
  });

  testWidgets('cancelling the photo picker changes nothing', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Add a photo'));
    await tester.pumpAndSettle();

    expect(find.text('Add a photo'), findsOneWidget);
  });

  testWidgets('hides "together since" until the user is in a couple', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Together since'), findsNothing);
  });

  testWidgets('sets "together since" for the couple', (tester) async {
    await pumpScreen(tester, couple: const CoupleSpace(id: 'c1'));
    expect(find.text('Choose a date'), findsOneWidget);

    await tester.tap(find.text('Choose a date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Sam');
    await save(tester);

    expect(
      couples.togetherSinceCalls.single,
      DateUtils.dateOnly(DateTime.now()),
    );
  });

  testWidgets('does not rewrite an unchanged "together since" date', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      profile: const Profile(id: 'u1', displayName: 'Sam'),
      couple: CoupleSpace(id: 'c1', togetherSince: DateTime(2023, 5, 14)),
    );
    expect(find.text('May 14, 2023'), findsOneWidget);

    await save(tester);

    expect(profiles.saves, hasLength(1));
    expect(couples.togetherSinceCalls, isEmpty);
  });

  testWidgets('shows the failure message and stays on the screen', (
    tester,
  ) async {
    await pumpScreen(tester);
    profiles.saveError = const ProfileFailure(
      'Could not upload the photo. Try again.',
    );

    await tester.enterText(find.byType(TextFormField), 'Sam');
    await save(tester);

    expect(find.text('Could not upload the photo. Try again.'), findsOneWidget);
    expect(find.text('HOME'), findsNothing);
  });

  testWidgets('load failure offers a retry', (tester) async {
    await pumpScreen(tester, loadError: StateError('offline'));
    expect(find.text('Could not load your profile.'), findsOneWidget);
    expect(find.textContaining('offline'), findsNothing);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Save'), findsOneWidget);
  });
}
