/// Invite codes are 6 letters/digits. People type them with spaces, dashes
/// and lower case, so input is normalized before use.
const inviteCodeLength = 6;

final _nonAlphanumeric = RegExp('[^A-Za-z0-9]');

String normalizeInviteCode(String input) =>
    input.replaceAll(_nonAlphanumeric, '').toUpperCase();

/// Returns an error message for [input], or null when it is a complete code.
String? validateInviteCode(String? input) {
  final code = normalizeInviteCode(input ?? '');
  if (code.isEmpty) return 'Enter the code from your partner';
  if (code.length != inviteCodeLength) {
    return 'The code has $inviteCodeLength characters';
  }
  return null;
}

/// Link that opens the app on the join screen with [code] filled in.
String inviteLink(String code) =>
    'com.ramilsalihar.ohana://invite/join/${normalizeInviteCode(code)}';
