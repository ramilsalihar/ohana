/// The signed-in user, independent of the auth backend.
class AppUser {
  const AppUser({required this.id, this.email});

  final String id;
  final String? email;

  @override
  bool operator ==(Object other) =>
      other is AppUser && other.id == id && other.email == email;

  @override
  int get hashCode => Object.hash(id, email);
}
