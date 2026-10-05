import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/supabase_profile_repository.dart';
import '../domain/profile.dart';
import '../domain/profile_repository.dart';

/// Override in tests with a fake.
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => SupabaseProfileRepository(Supabase.instance.client),
);

/// Lets the user choose a photo; returns null if they cancel.
typedef AvatarPicker = Future<AvatarImage?> Function();

final avatarPickerProvider = Provider<AvatarPicker>(
  (ref) => () async {
    // Downscaled on device: avatars are shown small, and it keeps uploads
    // well under the 2 MB limit.
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file == null) return null;
    final contentType =
        file.mimeType ?? AvatarImage.contentTypeForFileName(file.name);
    return AvatarImage(
      bytes: await file.readAsBytes(),
      contentType: contentType ?? 'application/octet-stream',
    );
  },
);
