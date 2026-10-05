import 'dart:typed_data';

class Profile {
  const Profile({required this.id, this.displayName, this.avatarPath});

  final String id;
  final String? displayName;

  /// Storage path of the avatar inside the private `avatars` bucket.
  final String? avatarPath;
}

/// A newly picked avatar image, not yet uploaded.
class AvatarImage {
  const AvatarImage({required this.bytes, required this.contentType});

  /// Largest avatar the server accepts (matches the bucket limit).
  static const maxBytes = 2 * 1024 * 1024;

  /// Content types the server accepts, with the file extension used for each.
  static const extensions = {
    'image/jpeg': 'jpg',
    'image/png': 'png',
    'image/webp': 'webp',
  };

  final Uint8List bytes;
  final String contentType;

  bool get isSupportedType => extensions.containsKey(contentType);
  bool get isTooLarge => bytes.lengthInBytes > maxBytes;

  /// Content type for a picked file name, or null if it is not supported.
  static String? contentTypeForFileName(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0) return null;
    return switch (name.substring(dot + 1).toLowerCase()) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => null,
    };
  }
}

const displayNameMaxLength = 50;

/// Returns an error message for [input], or null when it is a valid name.
String? validateDisplayName(String? input) {
  final name = input?.trim() ?? '';
  if (name.isEmpty) return 'Enter your name';
  if (name.length > displayNameMaxLength) {
    return 'Use $displayNameMaxLength characters or fewer';
  }
  return null;
}
