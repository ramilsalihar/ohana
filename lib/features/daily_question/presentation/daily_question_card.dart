import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../domain/daily_question.dart';
import '../domain/daily_question_repository.dart';
import 'daily_question_providers.dart';
import 'reveal_view.dart';

/// Today's question on the home screen: answer it, wait for the partner, then
/// see both answers.
///
/// With [previewOnly] (the partner has not joined yet) the question is shown
/// but cannot be answered.
class DailyQuestionCard extends ConsumerWidget {
  const DailyQuestionCard({super.key, this.previewOnly = false, this.date});

  final bool previewOnly;

  /// A past day to show instead of today (from history).
  final DateTime? date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(questionStatusProvider(date));
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: status.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => _LoadError(
            message: error is DailyQuestionFailure
                ? error.message
                : "Could not load today's question.",
            onRetry: () => ref.invalidate(questionStatusProvider(date)),
          ),
          data: (status) => status == null
              ? const Text('There was no question on this day.')
              : _QuestionBody(
                  // Start from a clean editor when the day or the saved
                  // answer changes.
                  key: ValueKey((status.question.date, status.myAnswer?.body)),
                  status: status,
                  previewOnly: previewOnly,
                  date: date,
                ),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    );
  }
}

class _QuestionBody extends ConsumerStatefulWidget {
  const _QuestionBody({
    super.key,
    required this.status,
    required this.previewOnly,
    required this.date,
  });

  final DailyQuestionStatus status;
  final bool previewOnly;
  final DateTime? date;

  @override
  ConsumerState<_QuestionBody> createState() => _QuestionBodyState();
}

class _QuestionBodyState extends ConsumerState<_QuestionBody> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(
    text: widget.status.myAnswer?.body ?? '',
  );

  bool _editing = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(dailyQuestionRepositoryProvider)
          .saveMyAnswer(widget.status.question.date, _controller.text.trim());
      ref.invalidate(questionStatusProvider(widget.date));
      if (widget.date != null) ref.invalidate(questionHistoryProvider);
    } on DailyQuestionFailure catch (e) {
      if (!mounted) return;
      if (e.reason == DailyQuestionFailureReason.answersLocked) {
        // The partner answered meanwhile. The card reloads into the reveal,
        // so say why the edit was not saved somewhere that survives it.
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
        ref.invalidate(questionStatusProvider(widget.date));
      } else {
        setState(() => _error = e.message);
      }
    } on Object {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = widget.status;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.date == null
              ? "Today's question"
              : MaterialLocalizations.of(
                  context,
                ).formatFullDate(status.question.date),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(status.question.text, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.lg),
        ..._content(theme, status),
      ],
    );
  }

  List<Widget> _content(ThemeData theme, DailyQuestionStatus status) {
    if (widget.previewOnly) {
      return [
        Text(
          'You can both answer once your partner joins.',
          style: theme.textTheme.bodyMedium,
        ),
      ];
    }
    if (status.isRevealed) {
      return [RevealView(status: status, date: widget.date)];
    }

    final myAnswer = status.myAnswer;
    if (myAnswer == null || _editing) return _editor(theme, status);

    return [
      Text('Your answer', style: theme.textTheme.labelMedium),
      const SizedBox(height: AppSpacing.xs),
      Text(myAnswer.body, style: theme.textTheme.bodyLarge),
      const SizedBox(height: AppSpacing.lg),
      ...[
        Semantics(
          liveRegion: true,
          child: Text(
            'Waiting for your partner…',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: () => setState(() => _editing = true),
            child: const Text('Edit answer'),
          ),
        ),
      ],
    ];
  }

  List<Widget> _editor(ThemeData theme, DailyQuestionStatus status) {
    final error = _error;
    return [
      Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          enabled: !_busy,
          minLines: 3,
          maxLines: 8,
          maxLength: answerMaxLength,
          maxLengthEnforcement: MaxLengthEnforcement.none,
          textCapitalization: TextCapitalization.sentences,
          buildCounter:
              (
                context, {
                required currentLength,
                required isFocused,
                required maxLength,
              }) => Text(
                '${answerLength(_controller.text)} / $answerMaxLength',
                style: theme.textTheme.bodySmall,
              ),
          decoration: const InputDecoration(
            hintText: 'Your answer',
            border: OutlineInputBorder(),
          ),
          validator: validateAnswer,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        status.hasAnswered
            ? 'You can change it until your partner answers.'
            : 'Your partner sees it only after they answer too.',
        style: theme.textTheme.bodySmall,
      ),
      const SizedBox(height: AppSpacing.md),
      FilledButton(
        onPressed: _busy ? null : _save,
        child: Text(
          _busy
              ? 'Saving…'
              : status.hasAnswered
              ? 'Save changes'
              : 'Share answer',
        ),
      ),
      if (status.hasAnswered)
        TextButton(
          onPressed: _busy
              ? null
              : () => setState(() {
                  _controller.text = status.myAnswer!.body;
                  _editing = false;
                  _error = null;
                }),
          child: const Text('Cancel'),
        ),
      if (error != null) ...[
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          liveRegion: true,
          child: Text(
            error,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ];
  }
}
