import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_spacing.dart';
import '../../couple/domain/couple_repository.dart';
import '../../couple/presentation/couple_providers.dart';
import '../domain/profile.dart';
import '../domain/profile_repository.dart';
import 'profile_providers.dart';

/// Set the display name, avatar and the couple's "together since" date.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  static const _genericError = 'Something went wrong. Please try again.';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  bool _loading = true;
  bool _loadFailed = false;
  bool _busy = false;
  String? _error;

  /// Null when the user is not in a couple yet; the date is then hidden.
  CoupleSpace? _couple;
  DateTime? _togetherSince;
  String? _currentAvatarUrl;
  AvatarImage? _newAvatar;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final profiles = ref.read(profileRepositoryProvider);
      final profile = await profiles.getMyProfile();
      final couple = await ref.read(coupleRepositoryProvider).getMyCouple();
      String? avatarUrl;
      final avatarPath = profile?.avatarPath;
      if (avatarPath != null) {
        try {
          avatarUrl = await profiles.avatarUrl(avatarPath);
        } on Object {
          // A missing picture should not block editing the profile.
        }
      }
      if (!mounted) return;
      setState(() {
        _nameController.text = profile?.displayName ?? '';
        _couple = couple;
        _togetherSince = couple?.togetherSince;
        _currentAvatarUrl = avatarUrl;
        _loading = false;
      });
    } on Object {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadFailed = true;
        });
      }
    }
  }

  Future<void> _pickAvatar() async {
    setState(() => _error = null);
    try {
      final picked = await ref.read(avatarPickerProvider)();
      if (picked == null || !mounted) return;
      if (!picked.isSupportedType) {
        setState(() => _error = 'Use a JPEG, PNG or WebP image.');
      } else if (picked.isTooLarge) {
        setState(() => _error = 'That image is too large (2 MB max).');
      } else {
        setState(() => _newAvatar = picked);
      }
    } on Object {
      if (mounted) setState(() => _error = 'Could not open your photos.');
    }
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _togetherSince ?? today,
      firstDate: DateTime(1950),
      lastDate: today,
      helpText: 'Together since',
    );
    if (picked != null && mounted) setState(() => _togetherSince = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(profileRepositoryProvider)
          .saveMyProfile(
            displayName: _nameController.text.trim(),
            newAvatar: _newAvatar,
          );
      final since = _togetherSince;
      if (_couple != null && since != null && since != _couple!.togetherSince) {
        await ref.read(coupleRepositoryProvider).setTogetherSince(since);
      }
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.home);
      }
    } on ProfileFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on CoupleFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on Object {
      if (mounted) setState(() => _error = _genericError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your profile')),
      body: SafeArea(
        child: Center(
          child: _loading
              ? const CircularProgressIndicator()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: _loadFailed ? _buildLoadFailed() : _buildForm(),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLoadFailed() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Could not load your profile.'),
        const SizedBox(height: AppSpacing.md),
        FilledButton(onPressed: _load, child: const Text('Try again')),
      ],
    );
  }

  Widget _buildForm() {
    final theme = Theme.of(context);
    final error = _error;
    final since = _togetherSince;
    final newAvatar = _newAvatar;
    final currentAvatarUrl = _currentAvatarUrl;

    final ImageProvider<Object>? avatarImage = newAvatar != null
        ? MemoryImage(newAvatar.bytes)
        : currentAvatarUrl != null
        ? NetworkImage(currentAvatarUrl)
        : null;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Semantics(
              image: true,
              label: avatarImage == null
                  ? 'No profile photo'
                  : 'Your profile photo',
              child: CircleAvatar(
                radius: 48,
                foregroundImage: avatarImage,
                child: const Icon(Icons.person, size: 48),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: TextButton(
              onPressed: _busy ? null : _pickAvatar,
              child: Text(avatarImage == null ? 'Add a photo' : 'Change photo'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _nameController,
            enabled: !_busy,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.givenName],
            maxLength: displayNameMaxLength,
            decoration: const InputDecoration(
              labelText: 'Your name',
              helperText: 'This is what your partner sees.',
              border: OutlineInputBorder(),
            ),
            validator: validateDisplayName,
          ),
          if (_couple != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Together since', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            OutlinedButton.icon(
              onPressed: _busy ? null : _pickDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                since == null
                    ? 'Choose a date'
                    : MaterialLocalizations.of(context).formatShortDate(since),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Shared with your partner. Either of you can change it.',
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(_busy ? 'Saving…' : 'Save'),
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
      ),
    );
  }
}
