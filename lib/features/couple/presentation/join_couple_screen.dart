import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_spacing.dart';
import '../domain/couple_repository.dart';
import '../domain/invite_code.dart';
import 'couple_providers.dart';

/// Join the partner's couple space with an invite code. [initialCode] is
/// pre-filled when the screen is opened from an invite link.
class JoinCoupleScreen extends ConsumerStatefulWidget {
  const JoinCoupleScreen({super.key, this.initialCode});

  final String? initialCode;

  @override
  ConsumerState<JoinCoupleScreen> createState() => _JoinCoupleScreenState();
}

class _JoinCoupleScreenState extends ConsumerState<JoinCoupleScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _codeController = TextEditingController(
    text: normalizeInviteCode(widget.initialCode ?? ''),
  );

  bool _busy = false;
  String? _error;

  /// True after the server reported that the user is alone in a space they
  /// created; joining then needs their consent to remove it.
  bool _offerLeaveEmptySpace = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join({bool leaveEmptySpace = false}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(coupleRepositoryProvider)
          .joinCouple(_codeController.text, leaveEmptySpace: leaveEmptySpace);
      ref.invalidate(myCoupleProvider);
      if (mounted) context.go(AppRoutes.home);
    } on CoupleFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _offerLeaveEmptySpace = e.reason == CoupleFailureReason.hasEmptySpace;
        _error = _offerLeaveEmptySpace ? null : e.message;
      });
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
    final error = _error;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Join your partner's space",
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Enter the 6-character code they shared with you.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      controller: _codeController,
                      enabled: !_busy,
                      autocorrect: false,
                      enableSuggestions: false,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        TextInputFormatter.withFunction(
                          (oldValue, newValue) => newValue.copyWith(
                            text: newValue.text.toUpperCase(),
                          ),
                        ),
                      ],
                      style: theme.textTheme.headlineSmall?.copyWith(
                        letterSpacing: 4,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Invite code',
                        border: OutlineInputBorder(),
                      ),
                      validator: validateInviteCode,
                      onChanged: (_) {
                        if (_offerLeaveEmptySpace) {
                          setState(() => _offerLeaveEmptySpace = false);
                        }
                      },
                      onFieldSubmitted: (_) => _join(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (_offerLeaveEmptySpace) ...[
                      Text(
                        'You already created a space of your own, and nobody '
                        'has joined it. Joining your partner removes that '
                        'empty space.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(
                        onPressed: _busy
                            ? null
                            : () => _join(leaveEmptySpace: true),
                        child: const Text("Join partner's space instead"),
                      ),
                    ] else
                      FilledButton(
                        onPressed: _busy ? null : _join,
                        child: Text(_busy ? 'Joining…' : 'Join'),
                      ),
                    if (!context.canPop()) ...[
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => context.go(AppRoutes.home),
                        child: const Text('Not now'),
                      ),
                    ],
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
