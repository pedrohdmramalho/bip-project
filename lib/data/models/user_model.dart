class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;

  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
  });
}
