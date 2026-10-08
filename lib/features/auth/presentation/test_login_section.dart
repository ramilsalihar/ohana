import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../domain/auth_repository.dart';
import '../domain/email_validator.dart';
import 'auth_providers.dart';

/// Email + password sign-in for test accounts. Only built when
/// [testLoginEnabledProvider] is true (debug builds with ENABLE_TEST_LOGIN).
class TestLoginSection extends ConsumerStatefulWidget {
  const TestLoginSection({super.key});

  static const minPasswordLength = 6;

  @override
  ConsumerState<TestLoginSection> createState() => _TestLoginSectionState();
}

class _TestLoginSectionState extends ConsumerState<TestLoginSection> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _busy = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool createAccount}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    final auth = ref.read(authRepositoryProvider);
    try {
      if (createAccount) {
        final signedIn = await auth.signUpWithPassword(
          _email.text,
          _password.text,
        );
        if (!signedIn && mounted) {
          setState(() {
            _messageIsError = false;
            _message =
                'Account created, but the project requires email '
                'confirmation. Confirm it, or turn off "Confirm email" in '
                'Supabase for testing, then sign in.';
          });
        }
      } else {
        await auth.signInWithPassword(_email.text, _password.text);
      }
      // On success the router moves on by itself.
    } on AuthFailure catch (e) {
      if (mounted) {
        setState(() {
          _messageIsError = true;
          _message = e.message;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _messageIsError = true;
          _message = 'Something went wrong. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = _message;
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Test sign-in (debug only)',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('test-login-email'),
                controller: _email,
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Test email',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: validateEmail,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                key: const Key('test-login-password'),
                controller: _password,
                enabled: !_busy,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (value) =>
                    (value ?? '').length < TestLoginSection.minPasswordLength
                    ? 'At least ${TestLoginSection.minPasswordLength} characters'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => _submit(createAccount: true),
                      child: const Text('Create'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy
                          ? null
                          : () => _submit(createAccount: false),
                      child: const Text('Sign in'),
                    ),
                  ),
                ],
              ),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _messageIsError ? theme.colorScheme.error : null,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
