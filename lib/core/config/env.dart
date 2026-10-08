import 'package:flutter/foundation.dart';

/// Build-time environment configuration.
///
/// Values come from `--dart-define-from-file=.env`; see `.env.example`.
class Env {
  const Env({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    this.testLoginRequested = false,
  });

  /// Values compiled into this build. Empty strings when not provided.
  static const Env current = Env(
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
    testLoginRequested: bool.fromEnvironment('ENABLE_TEST_LOGIN'),
  );

  final String supabaseUrl;
  final String supabaseAnonKey;

  /// `ENABLE_TEST_LOGIN=true` was set for this build.
  final bool testLoginRequested;

  /// Email + password sign-in for testing. Needs the flag AND a debug build,
  /// so it can never ship in a release build by accident.
  bool get testLoginEnabled => testLoginRequested && kDebugMode;

  /// Names of required values that are missing.
  List<String> get missing => [
    if (supabaseUrl.trim().isEmpty) 'SUPABASE_URL',
    if (supabaseAnonKey.trim().isEmpty) 'SUPABASE_ANON_KEY',
  ];

  bool get isConfigured => missing.isEmpty;
}
