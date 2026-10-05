final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

/// Returns an error message for [input], or null when it looks like an email.
/// Deliberately loose: the real check is whether the magic link arrives.
String? validateEmail(String? input) {
  final email = input?.trim() ?? '';
  if (email.isEmpty) return 'Enter your email';
  if (!_emailPattern.hasMatch(email)) return 'Enter a valid email';
  return null;
}
