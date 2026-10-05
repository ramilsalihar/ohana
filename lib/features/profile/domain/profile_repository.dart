import 'profile.dart';

/// The signed-in user's own profile. Implemented by Supabase in production
/// and by fakes in tests.
abstract interface class ProfileRepository {
  /// The current user's profile, or null if they have not set one up yet.
  Future<Profile?> getMyProfile();

  /// Saves the display name and, when [newAvatar] is given, uploads it and
  /// makes it the profile picture.
  Future<void> saveMyProfile({
    required String displayName,
    AvatarImage? newAvatar,
  });

  /// A short-lived URL for showing the avatar stored at [avatarPath].
  Future<String> avatarUrl(String avatarPath);
}

/// A profile operation failed. [message] is safe to show to the user.
class ProfileFailure implements Exception {
  const ProfileFailure(this.message);

  final String message;

  @override
  String toString() => 'ProfileFailure: $message';
}
