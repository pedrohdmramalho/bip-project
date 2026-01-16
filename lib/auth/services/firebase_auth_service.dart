import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/models/user_model.dart';
import 'auth_service.dart';

class FirebaseAuthService implements AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _isInitialized = false;

  AppUser? _userFromFirebase(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
    );
  }

  Future<void> _initializeGoogleSignIn() async {
    if (!_isInitialized) {
      _isInitialized = true;
    }
  }

  @override
  Future<bool> signInWithGoogle() async {
    try {
      await _initializeGoogleSignIn();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _firebaseAuth.signInWithCredential(credential);

      return true;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.message}');
      return false;
    } catch (e) {
      print('Error during Google Sign-In: $e');
      return false;
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }

  @override
  AppUser? get currentUser => _userFromFirebase(_firebaseAuth.currentUser);

  @override
  Stream<AppUser?> get authStateChanges =>
      _firebaseAuth.authStateChanges().map(_userFromFirebase);
}
