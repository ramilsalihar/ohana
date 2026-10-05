import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/profile.dart';
import '../domain/profile_repository.dart';

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  static const _bucket = 'avatars';
  static const _signedUrlSeconds = 60 * 60;

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const ProfileFailure('Please sign in again.');
    return id;
  }

  @override
  Future<Profile?> getMyProfile() => _guard(() async {
    final id = _userId;
    final row = await _client
        .from('profiles')
        .select('id, display_name, avatar_url')
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return Profile(
      id: row['id'] as String,
      displayName: row['display_name'] as String?,
      avatarPath: row['avatar_url'] as String?,
    );
  });

  @override
  Future<void> saveMyProfile({
    required String displayName,
    AvatarImage? newAvatar,
  }) => _guard(() async {
    final id = _userId;
    final values = <String, Object?>{
      'id': id,
      'display_name': displayName.trim(),
    };

    if (newAvatar != null) {
      final extension = AvatarImage.extensions[newAvatar.contentType];
      if (extension == null) {
        throw const ProfileFailure('Use a JPEG, PNG or WebP image.');
      }
      if (newAvatar.isTooLarge) {
        throw const ProfileFailure('That image is too large (2 MB max).');
      }
      // The folder name is what the storage policy checks.
      final path = '$id/avatar.$extension';
      await _client.storage
          .from(_bucket)
          .uploadBinary(
            path,
            newAvatar.bytes,
            fileOptions: FileOptions(
              contentType: newAvatar.contentType,
              upsert: true,
            ),
          );
      values['avatar_url'] = path;
    }

    await _client.from('profiles').upsert(values);
  });

  @override
  Future<String> avatarUrl(String avatarPath) => _guard(
    () => _client.storage
        .from(_bucket)
        .createSignedUrl(avatarPath, _signedUrlSeconds),
  );

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException {
      throw const ProfileFailure('Could not save your profile. Try again.');
    } on StorageException {
      throw const ProfileFailure('Could not upload the photo. Try again.');
    }
  }
}
