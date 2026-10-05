import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/supabase_couple_repository.dart';
import '../domain/couple_repository.dart';

/// Override in tests with a fake.
final coupleRepositoryProvider = Provider<CoupleRepository>(
  (ref) => SupabaseCoupleRepository(Supabase.instance.client),
);

/// Reads the device's IANA time zone, e.g. `Europe/Berlin`. The couple's time
/// zone is set from the first member's device (PRD F2).
typedef DeviceTimezoneReader = Future<String> Function();

final deviceTimezoneReaderProvider = Provider<DeviceTimezoneReader>(
  (ref) => () async {
    try {
      return (await FlutterTimezone.getLocalTimezone()).identifier;
    } on Object {
      return 'UTC';
    }
  },
);
