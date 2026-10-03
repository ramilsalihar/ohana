import 'package:flutter_test/flutter_test.dart';

import 'package:ohana/core/config/env.dart';

void main() {
  group('Env', () {
    test('is configured when both values are present', () {
      const env = Env(
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'anon-key',
      );

      expect(env.isConfigured, isTrue);
      expect(env.missing, isEmpty);
    });

    test('reports missing values by name', () {
      const env = Env(supabaseUrl: ' ', supabaseAnonKey: '');

      expect(env.isConfigured, isFalse);
      expect(env.missing, ['SUPABASE_URL', 'SUPABASE_ANON_KEY']);
    });

    test('reports only the value that is missing', () {
      const env = Env(
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: '',
      );

      expect(env.missing, ['SUPABASE_ANON_KEY']);
    });

    test('current is unconfigured when no dart-defines are passed', () {
      expect(Env.current.isConfigured, isFalse);
    });
  });
}
