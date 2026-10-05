import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Returns the current time. Override in tests for a fixed "now".
typedef Clock = DateTime Function();

final clockProvider = Provider<Clock>((ref) => DateTime.now);
