import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../domain/daily_question.dart';
import '../domain/daily_question_repository.dart';
import 'daily_question_providers.dart';

/// Both answers, shown once both partners have answered, with the reaction
/// each left on the other's answer.
class RevealView extends ConsumerStatefulWidget {
  const RevealView({super.key, required this.status, this.date});

  final DailyQuestionStatus status;

  /// The day being shown; null means today.
  final DateTime? date;

  @override
  ConsumerState<RevealView> createState() => _RevealViewState();
}

class _RevealViewState extends ConsumerState<RevealView> {
  final _formKey = GlobalKey<FormState>();
  late final _commentController = TextEditingController(
    text: widget.status.myReaction?.comment ?? '',
  );

  bool _busy = false;
  String? _error;

  String get _partnerName => widget.status.partnerName ?? 'Your partner';

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _setReaction(Reaction reaction) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(dailyQuestionRepositoryProvider)
          .setMyReaction(widget.status.partnerAnswer!.id, reaction);
      ref.invalidate(questionStatusProvider(widget.date));
    } on DailyQuestionFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on Object {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Tapping the selected emoji again removes it.
  Future<void> _toggleEmoji(String emoji) {
    final current = widget.status.myReaction;
    return _setReaction(
      Reaction(
        emoji: current?.emoji == emoji ? null : emoji,
        comment: current?.comment,
      ),
    );
  }

  Future<void> _saveComment() async {
    if (!_formKey.currentState!.validate()) return;
    final text = _commentController.text.trim();
    await _setReaction(
      Reaction(
        emoji: widget.status.myReaction?.emoji,
        comment: text.isEmpty ? null : text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final mine = _AnswerBlock(
      label: 'You',
      body: status.myAnswer!.body,
      footer: _partnerReaction(context),
    );
    final theirs = _AnswerBlock(
      label: _partnerName,
      body: status.partnerAnswer!.body,
      footer: _myReactionControls(context),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Side by side when there is room; stacked on a narrow phone.
        if (constraints.maxWidth >= 520) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: mine),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: theirs),
            ],
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            mine,
            const SizedBox(height: AppSpacing.lg),
            theirs,
          ],
        );
      },
    );
  }

  /// What the partner left on the current user's answer, if anything.
  Widget? _partnerReaction(BuildContext context) {
    final reaction = widget.status.partnerReaction;
    if (reaction == null || reaction.isEmpty) return null;
    final theme = Theme.of(context);
    final emoji = reaction.emoji;
    final comment = reaction.comment;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (emoji != null)
          Text(
            '$_partnerName reacted $emoji',
            style: theme.textTheme.bodyMedium,
          ),
        if (comment != null)
          Text('$_partnerName: $comment', style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Widget _myReactionControls(BuildContext context) {
    final theme = Theme.of(context);
    final selected = widget.status.myReaction?.emoji;
    final savedComment = widget.status.myReaction?.comment ?? '';
    final error = _error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            for (final emoji in reactionEmojis)
              Semantics(
                button: true,
                selected: emoji == selected,
                label: 'React with $emoji',
                child: ExcludeSemantics(
                  child: ChoiceChip(
                    label: Text(emoji),
                    selected: emoji == selected,
                    showCheckmark: false,
                    onSelected: _busy ? null : (_) => _toggleEmoji(emoji),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _commentController,
            enabled: !_busy,
            minLines: 1,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Add a short comment',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            validator: validateReactionComment,
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (_commentController.text.trim() != savedComment)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: _busy ? null : _saveComment,
              child: Text(
                _commentController.text.trim().isEmpty
                    ? 'Remove comment'
                    : 'Send comment',
              ),
            ),
          ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Semantics(
            liveRegion: true,
            child: Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AnswerBlock extends StatelessWidget {
  const _AnswerBlock({required this.label, required this.body, this.footer});

  final String label;
  final String body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final footer = this.footer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(body, style: theme.textTheme.bodyLarge),
        if (footer != null) ...[const SizedBox(height: AppSpacing.sm), footer],
      ],
    );
  }
}
