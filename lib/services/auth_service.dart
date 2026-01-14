import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser; // Informação sobre o usuário autenticado.

  // Avisa quando o estado de login muda.
  Stream<User?> authStateChanges() => _auth.authStateChanges();
  // Login Anonimo
  Future<UserCredential> signInAnonymously() => _auth.signInAnonymously();
  // Logout
  Future<void> signOut() => _auth.signOut();
}
