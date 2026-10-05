import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../domain/couple_repository.dart';
import '../domain/invite.dart';
import '../domain/invite_code.dart';
import 'couple_providers.dart';

/// Creates the couple space and shows the invite code to share.
class CreateCoupleScreen extends ConsumerStatefulWidget {
  const CreateCoupleScreen({super.key});

  @override
  ConsumerState<CreateCoupleScreen> createState() => _CreateCoupleScreenState();
}

class _CreateCoupleScreenState extends ConsumerState<CreateCoupleScreen> {
  bool _busy = false;
  String? _error;
  Invite? _invite;

  Future<void> _create() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final couples = ref.read(coupleRepositoryProvider);
      final timezone = await ref.read(deviceTimezoneReaderProvider)();
      try {
        await couples.createCouple(timezone: timezone);
      } on CoupleFailure catch (e) {
        // The space already exists (e.g. an earlier attempt got this far);
        // carry on and fetch its invite.
        if (e.reason != CoupleFailureReason.alreadyInCouple) rethrow;
      }
      final invite = await couples.createInvite();
      ref.invalidate(myCoupleProvider);
      if (mounted) setState(() => _invite = invite);
    } on CoupleFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
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
    final invite = _invite;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: invite == null
                  ? _buildIntro(context)
                  : _InviteView(invite: invite),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntro(BuildContext context) {
    final theme = Theme.of(context);
    final error = _error;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Create your space', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'A private space for the two of you. You will get a code to share '
          'with your partner.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: _busy ? null : _create,
          child: Text(_busy ? 'Creating…' : 'Create our space'),
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.lg),
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
      ],
    );
  }
}

class _InviteView extends StatelessWidget {
  const _InviteView({required this.invite});

  final Invite invite;

  Future<void> _copy(BuildContext context, String text, String done) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = invite.daysLeft(DateTime.now());
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Invite your partner', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Share this code or the invite link. They use it after signing in.',
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        Semantics(
          label: 'Invite code ${invite.code.split('').join(' ')}',
          child: ExcludeSemantics(
            child: SelectableText(
              invite.code,
              style: theme.textTheme.displaySmall?.copyWith(letterSpacing: 6),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Works once · expires in $days ${days == 1 ? 'day' : 'days'}',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton.icon(
          onPressed: () => _copy(context, invite.code, 'Code copied'),
          icon: const Icon(Icons.copy),
          label: const Text('Copy code'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: () =>
              _copy(context, inviteLink(invite.code), 'Link copied'),
          child: const Text('Copy invite link'),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Waiting for your partner to join…',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
