import 'package:ohana/features/profile/domain/profile.dart';
import 'package:ohana/features/profile/domain/profile_repository.dart';

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({this.profile});

  Profile? profile;

  /// When set, the matching call throws it once.
  Object? loadError;
  Object? saveError;

  final List<({String displayName, AvatarImage? newAvatar})> saves = [];

  @override
  Future<Profile?> getMyProfile() async {
    final error = loadError;
    loadError = null;
    if (error != null) Error.throwWithStackTrace(error, StackTrace.current);
    return profile;
  }

  @override
  Future<void> saveMyProfile({
    required String displayName,
    AvatarImage? newAvatar,
  }) async {
    final error = saveError;
    saveError = null;
    if (error != null) Error.throwWithStackTrace(error, StackTrace.current);
    saves.add((displayName: displayName, newAvatar: newAvatar));
  }

  @override
  Future<String> avatarUrl(String avatarPath) async =>
      throw StateError('no network in tests');
}
