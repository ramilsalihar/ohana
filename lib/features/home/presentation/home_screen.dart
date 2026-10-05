import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/format_count.dart';
import '../../activity/presentation/activity_strip.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../couple/domain/couple_repository.dart';
import '../../couple/presentation/couple_providers.dart';
import '../../daily_question/presentation/daily_question_card.dart';
import '../../daily_question/presentation/daily_question_providers.dart';
import '../../daily_question/presentation/streak_badge.dart';
import '../domain/together_counter.dart';

/// Home shell: shows the together counter, or the next step toward it
/// (create/join a space, wait for the partner, set the start date).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couple = ref.watch(myCoupleProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ohana'),
        actions: [
          IconButton(
            tooltip: 'Your profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(AppRoutes.profileSetup),
          ),
          PopupMenuButton<void>(
            tooltip: 'More',
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: () =>
                    unawaited(ref.read(authRepositoryProvider).signOut()),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        // Pull down to pick up what the partner has done since the screen
        // loaded.
        child: RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(myCoupleProvider)
              ..invalidate(questionStatusProvider(null))
              ..invalidate(streakProvider)
              ..invalidate(partnerActivityProvider);
            await ref.read(myCoupleProvider.future).catchError((_) => null);
          },
          child: _body(context, ref, couple),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<CoupleSpace?> couple,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: ConstrainedBox(
          // Fill the viewport so short content stays centred and the whole
          // screen can be pulled.
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight - AppSpacing.screen * 2,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: couple.when(
                loading: () => const CircularProgressIndicator(),
                error: (_, _) => _Step(
                  title: 'Could not load your space',
                  body: 'Check your connection and try again.',
                  primaryLabel: 'Try again',
                  onPrimary: () => ref.invalidate(myCoupleProvider),
                ),
                data: (space) => _content(context, ref, space),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, CoupleSpace? space) {
    if (space == null) {
      return _Step(
        title: 'Start your space',
        body:
            'Ohana is for the two of you. Create a space and invite your '
            'partner, or join theirs with a code.',
        primaryLabel: 'Create our space',
        onPrimary: () => context.push(AppRoutes.createCouple),
        secondaryLabel: 'Join with a code',
        onSecondary: () => context.push(AppRoutes.join),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _coupleStatus(context, ref, space),
        if (!space.isWaitingForPartner) ...[
          const SizedBox(height: AppSpacing.lg),
          const StreakBadge(),
          const ActivityStrip(),
        ],
        const SizedBox(height: AppSpacing.xl),
        DailyQuestionCard(previewOnly: space.isWaitingForPartner),
        if (!space.isWaitingForPartner) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => context.push(AppRoutes.history),
            child: const Text('Past questions'),
          ),
        ],
      ],
    );
  }

  Widget _coupleStatus(BuildContext context, WidgetRef ref, CoupleSpace space) {
    if (space.isWaitingForPartner) {
      return _Step(
        title: 'Waiting for your partner',
        body:
            'Your space is ready. It comes to life once your partner joins '
            'with your invite code.',
        primaryLabel: 'Show invite code',
        onPrimary: () => context.push(AppRoutes.createCouple),
        secondaryLabel: 'Check again',
        onSecondary: () => ref.invalidate(myCoupleProvider),
      );
    }
    final since = space.togetherSince;
    final counter = since == null
        ? null
        : TogetherCounter(since: since, today: ref.watch(clockProvider)());
    if (counter == null || !counter.hasStarted) {
      return _Step(
        title: 'When did you get together?',
        body: 'Add the date and Ohana will count your days together.',
        primaryLabel: 'Add the date',
        onPrimary: () => context.push(AppRoutes.profileSetup),
      );
    }
    return _TogetherCounterView(counter: counter);
  }
}

class _TogetherCounterView extends StatelessWidget {
  const _TogetherCounterView({required this.counter});

  final TogetherCounter counter;

  static String _milestoneName(Milestone m) => switch (m.kind) {
    MilestoneKind.hundredDays => 'Day ${formatCount(m.value)}',
    MilestoneKind.anniversary =>
      '${m.value} ${m.value == 1 ? 'year' : 'years'} together',
  };

  static String _milestoneText(Milestone m) {
    final name = _milestoneName(m);
    if (m.isToday) return 'Today: $name';
    if (m.daysUntil == 1) return '$name is tomorrow';
    return '$name in ${formatCount(m.daysUntil)} days';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final day = formatCount(counter.dayNumber);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MergeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Day', style: theme.textTheme.titleMedium),
              Text(
                day,
                style: theme.textTheme.displayLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              Text('together', style: theme.textTheme.titleMedium),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          _milestoneText(counter.nextMilestone),
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// A prompt for the next step the user needs to take.
class _Step extends StatelessWidget {
  const _Step({
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final secondaryLabel = this.secondaryLabel;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(body, style: textTheme.bodyLarge, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(onPressed: onPrimary, child: Text(primaryLabel)),
        if (secondaryLabel != null) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(onPressed: onSecondary, child: Text(secondaryLabel)),
        ],
      ],
    );
  }
}
