import 'package:flutter_test/flutter_test.dart';

import 'package:ohana/features/auth/domain/email_validator.dart';

void main() {
  test('accepts ordinary addresses, ignoring surrounding spaces', () {
    expect(validateEmail('sam@example.com'), isNull);
    expect(validateEmail('  sam.lee+ohana@mail.example.co  '), isNull);
  });

  test('asks for an email when empty', () {
    expect(validateEmail(null), 'Enter your email');
    expect(validateEmail('   '), 'Enter your email');
  });

  test('rejects malformed addresses', () {
    for (final bad in [
      'sam',
      'sam@',
      '@example.com',
      'sam@example',
      'a b@c.de',
    ]) {
      expect(validateEmail(bad), 'Enter a valid email', reason: bad);
    }
  });
}
