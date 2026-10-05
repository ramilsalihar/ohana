import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/supabase_daily_question_repository.dart';
import '../domain/daily_question.dart';
import '../domain/daily_question_repository.dart';
import '../domain/streak.dart';

/// Override in tests with a fake.
final dailyQuestionRepositoryProvider = Provider<DailyQuestionRepository>(
  (ref) => SupabaseDailyQuestionRepository(Supabase.instance.client),
);

/// A day's question and answers; a null date means today. Invalidate after
/// saving an answer or reaction.
final questionStatusProvider =
    FutureProvider.family<DailyQuestionStatus?, DateTime?>(
      (ref, date) {
        final repository = ref.watch(dailyQuestionRepositoryProvider);
        return date == null ? repository.getToday() : repository.getDay(date);
      },
      // No silent background retries: the card shows the error with a
      // "Try again" button instead.
      retry: (_, _) => null,
    );

/// Past questions, newest first. Invalidate after answering a past day.
final questionHistoryProvider = FutureProvider<List<QuestionHistoryEntry>>(
  (ref) => ref.watch(dailyQuestionRepositoryProvider).getHistory(),
  retry: (_, _) => null,
);

/// The couple's streak. Invalidate after saving an answer.
final streakProvider = FutureProvider<Streak?>(
  (ref) => ref.watch(dailyQuestionRepositoryProvider).getStreak(),
  retry: (_, _) => null,
);
