import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/models/user_model.dart'; // Import your AppUser
import 'auth_service.dart'; // Import the Interface

// 1. You must implement AuthService
class FirebaseAuthService implements AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _isInitialized = false;

  // --- Helper to convert Firebase User -> AppUser ---
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
      // NOTE: .initialize() might not be needed depending on plugin version,
      // but keeping it since you requested it.
      // await _googleSignIn.initialize();
      _isInitialized = true;
    }
  }

  @override
  Future<bool> signInWithGoogle() async {
    try {
      await _initializeGoogleSignIn();

      // NOTE: If you downgraded to version 6.2.1 (recommended for Android),
      // use .signIn() instead of .authenticate()
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken, // Required for Android usually
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

  // 2. Return AppUser, not Firebase User
  @override
  AppUser? get currentUser => _userFromFirebase(_firebaseAuth.currentUser);

  // 3. Map the Stream to AppUser
  @override
  Stream<AppUser?> get authStateChanges =>
      _firebaseAuth.authStateChanges().map(_userFromFirebase);
}
