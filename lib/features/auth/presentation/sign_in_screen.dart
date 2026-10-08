import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../domain/auth_repository.dart';
import '../domain/email_validator.dart';
import 'auth_providers.dart';
import 'test_login_section.dart';

/// Sign in with an email magic link, Apple or Google.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _busy = false;
  String? _error;
  String? _linkSentTo;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function(AuthRepository auth) action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action(ref.read(authRepositoryProvider));
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on Object {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendMagicLink() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    await _run((auth) async {
      await auth.sendMagicLink(email);
      if (mounted) setState(() => _linkSentTo = email);
    });
  }

  @override
  Widget build(BuildContext context) {
    final linkSentTo = _linkSentTo;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: linkSentTo != null
                  ? _LinkSent(
                      email: linkSentTo,
                      onUseDifferentEmail: () =>
                          setState(() => _linkSentTo = null),
                    )
                  : _buildForm(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    final error = _error;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Sign in to Ohana', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'We will email you a link. No password needed.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          TextFormField(
            controller: _emailController,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            validator: validateEmail,
            onFieldSubmitted: (_) => _sendMagicLink(),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: _busy ? null : _sendMagicLink,
            child: const Text('Email me a sign-in link'),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text('or', style: theme.textTheme.bodySmall),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton(
            onPressed: _busy
                ? null
                : () => _run((auth) => auth.signInWithApple()),
            child: const Text('Continue with Apple'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: _busy
                ? null
                : () => _run((auth) => auth.signInWithGoogle()),
            child: const Text('Continue with Google'),
          ),
          if (ref.watch(testLoginEnabledProvider)) ...[
            const SizedBox(height: AppSpacing.xl),
            const TestLoginSection(),
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
    );
  }
}

class _LinkSent extends StatelessWidget {
  const _LinkSent({required this.email, required this.onUseDifferentEmail});

  final String email;
  final VoidCallback onUseDifferentEmail;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Check your email', style: textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.md),
        Text(
          'We sent a sign-in link to $email. Open it on this device to '
          'continue.',
          style: textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        TextButton(
          onPressed: onUseDifferentEmail,
          child: const Text('Use a different email'),
        ),
      ],
    );
  }
}
