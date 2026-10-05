import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/supabase_daily_question_repository.dart';
import '../domain/daily_question.dart';
import '../domain/daily_question_repository.dart';

/// Override in tests with a fake.
final dailyQuestionRepositoryProvider = Provider<DailyQuestionRepository>(
  (ref) => SupabaseDailyQuestionRepository(Supabase.instance.client),
);

/// Today's question and answers. Invalidate after saving an answer.
final todayQuestionProvider = FutureProvider<DailyQuestionStatus>(
  (ref) => ref.watch(dailyQuestionRepositoryProvider).getToday(),
  // No silent background retries: the card shows the error with a
  // "Try again" button instead.
  retry: (_, _) => null,
);
