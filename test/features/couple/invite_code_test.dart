import 'package:flutter_test/flutter_test.dart';

import 'package:ohana/features/couple/domain/invite_code.dart';

void main() {
  test('normalizes case, spaces and dashes', () {
    expect(normalizeInviteCode(' v69-nx6 '), 'V69NX6');
    expect(normalizeInviteCode('V 6 9 N X 6'), 'V69NX6');
    expect(normalizeInviteCode(''), '');
  });

  test('validates length after normalizing', () {
    expect(validateInviteCode('v69-nx6'), isNull);
    expect(validateInviteCode(null), 'Enter the code from your partner');
    expect(validateInviteCode(' - '), 'Enter the code from your partner');
    expect(validateInviteCode('V69N'), 'The code has 6 characters');
    expect(validateInviteCode('V69NX6X'), 'The code has 6 characters');
  });

  test('builds an invite link the router can open', () {
    final link = Uri.parse(inviteLink('v69nx6'));
    expect(link.scheme, 'com.ramilsalihar.ohana');
    expect(link.host, 'invite');
    expect(link.path, '/join/V69NX6');
  });
}
