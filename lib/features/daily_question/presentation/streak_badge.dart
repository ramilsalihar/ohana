import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/format_count.dart';
import '../domain/streak.dart';
import 'daily_question_providers.dart';

/// One calm line about the couple's streak. It is always about "us": it
/// never says who answered or who missed, and a broken streak is an
/// invitation, not a reprimand.
class StreakBadge extends ConsumerWidget {
  const StreakBadge({super.key});

  static String label(Streak streak) {
    if (streak.days == 1) return '1 day in a row together';
    if (streak.days > 1) {
      return '${formatCount(streak.days)} days in a row together';
    }
    return streak.hasHistory
        ? 'Start a new streak together'
        : 'Answer together to start a streak';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The streak is a nicety: while loading, or if it fails, show nothing.
    final streak = ref.watch(streakProvider).value;
    if (streak == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Text(
      label(streak),
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    );
  }
}
