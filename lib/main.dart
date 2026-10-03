import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const env = Env.current;
  if (env.isConfigured) {
    await Supabase.initialize(
      url: env.supabaseUrl,
      publishableKey: env.supabaseAnonKey,
    );
  }

  runApp(ProviderScope(child: OhanaApp(missingEnv: env.missing)));
}
