/// Build-time environment configuration.
///
/// Values come from `--dart-define-from-file=.env`; see `.env.example`.
class Env {
  const Env({required this.supabaseUrl, required this.supabaseAnonKey});

  /// Values compiled into this build. Empty strings when not provided.
  static const Env current = Env(
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  final String supabaseUrl;
  final String supabaseAnonKey;

  /// Names of required values that are missing.
  List<String> get missing => [
    if (supabaseUrl.trim().isEmpty) 'SUPABASE_URL',
    if (supabaseAnonKey.trim().isEmpty) 'SUPABASE_ANON_KEY',
  ];

  bool get isConfigured => missing.isEmpty;
}
