import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/utils/date_only.dart';
import '../domain/daily_question.dart';
import 'daily_question_card.dart';
import 'daily_question_providers.dart';

/// Past daily questions. Days the user has not answered can still be
/// answered from here, with no penalty for being late.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  static String _statusLabel(HistoryStatus status) => switch (status) {
    HistoryStatus.unanswered => 'Answer',
    HistoryStatus.waiting => 'Waiting for your partner',
    HistoryStatus.revealed => 'Both answered',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(questionHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Past questions')),
      body: SafeArea(
        child: history.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Could not load past questions.'),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => ref.invalidate(questionHistoryProvider),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
          data: (entries) => entries.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.screen),
                    child: Text(
                      'Your past questions will appear here.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final localizations = MaterialLocalizations.of(context);
                    return ListTile(
                      title: Text(entry.question.text),
                      subtitle: Text(
                        '${localizations.formatMediumDate(entry.question.date)}'
                        ' · ${_statusLabel(entry.status)}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(
                        AppRoutes.historyDay(
                          formatDateOnly(entry.question.date),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

/// One past day: the same card as on Home, for that day's question.
class HistoryDayScreen extends StatelessWidget {
  const HistoryDayScreen({super.key, required this.date});

  /// `YYYY-MM-DD` from the route.
  final String date;

  @override
  Widget build(BuildContext context) {
    final parsed = DateTime.tryParse(date);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: parsed == null
                  ? const Text('There was no question on this day.')
                  : DailyQuestionCard(
                      date: DateTime(parsed.year, parsed.month, parsed.day),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
