import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:ohana/features/profile/domain/profile.dart';

void main() {
  test('display name is required and trimmed', () {
    expect(validateDisplayName('Sam'), isNull);
    expect(validateDisplayName('  Sam  '), isNull);
    expect(validateDisplayName(null), 'Enter your name');
    expect(validateDisplayName('   '), 'Enter your name');
  });

  test('display name is limited to 50 characters', () {
    expect(validateDisplayName('a' * 50), isNull);
    expect(validateDisplayName('a' * 51), 'Use 50 characters or fewer');
  });

  test('avatar content type is derived from the file name', () {
    expect(AvatarImage.contentTypeForFileName('me.JPG'), 'image/jpeg');
    expect(AvatarImage.contentTypeForFileName('me.jpeg'), 'image/jpeg');
    expect(AvatarImage.contentTypeForFileName('a.b.png'), 'image/png');
    expect(AvatarImage.contentTypeForFileName('me.webp'), 'image/webp');
    expect(AvatarImage.contentTypeForFileName('me.heic'), isNull);
    expect(AvatarImage.contentTypeForFileName('noextension'), isNull);
  });

  test('avatar type and size limits', () {
    final small = AvatarImage(bytes: Uint8List(10), contentType: 'image/png');
    final gif = AvatarImage(bytes: Uint8List(10), contentType: 'image/gif');
    final big = AvatarImage(
      bytes: Uint8List(AvatarImage.maxBytes + 1),
      contentType: 'image/jpeg',
    );
    final atLimit = AvatarImage(
      bytes: Uint8List(AvatarImage.maxBytes),
      contentType: 'image/jpeg',
    );

    expect(small.isSupportedType, isTrue);
    expect(small.isTooLarge, isFalse);
    expect(gif.isSupportedType, isFalse);
    expect(big.isTooLarge, isTrue);
    expect(atLimit.isTooLarge, isFalse);
  });
}
