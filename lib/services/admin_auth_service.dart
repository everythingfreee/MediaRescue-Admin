import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/admin_user_model.dart';

class UnauthorizedAdminException implements Exception {
  final String message;
  UnauthorizedAdminException(this.message);

  @override
  String toString() => message;
}

class AdminAuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AdminAuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Authenticates with Google, checks the admin_users collection allowlist,
  /// and returns the AdminUserModel if active. If unauthorized, forces signOut().
  Future<AdminUserModel> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign in was canceled by the user.');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null || user.email == null) {
        await signOut();
        throw UnauthorizedAdminException('Failed to retrieve user email from Google Authentication.');
      }

      // Force ID Token refresh so Cloud Firestore SDK instantly updates its internal auth state
      await user.getIdToken(true);

      final normalizedEmail = user.email!.toLowerCase().trim();
      final adminDoc = await _firestore.collection('admin_users').doc(normalizedEmail).get();

      if (!adminDoc.exists) {
        await signOut();
        throw UnauthorizedAdminException(
          'Unauthorized account ($normalizedEmail). Email not listed in admin_users database.',
        );
      }

      final adminUser = AdminUserModel.fromFirestore(adminDoc);
      if (!adminUser.active) {
        await signOut();
        throw UnauthorizedAdminException(
          'Unauthorized account ($normalizedEmail). Your admin account is disabled or inactive.',
        );
      }

      return adminUser;
    } catch (e) {
      if (e is! UnauthorizedAdminException) {
        await signOut();
      }
      rethrow;
    }
  }

  /// Verifies current user's allowlist status in Firestore
  Future<AdminUserModel?> verifyCurrentAdminStatus() async {
    final user = currentUser;
    if (user == null || user.email == null) return null;

    final normalizedEmail = user.email!.toLowerCase().trim();
    final doc = await _firestore.collection('admin_users').doc(normalizedEmail).get();

    if (!doc.exists) {
      await signOut();
      return null;
    }

    final adminUser = AdminUserModel.fromFirestore(doc);
    if (!adminUser.active) {
      await signOut();
      return null;
    }

    return adminUser;
  }

  /// Sign out cleanup method
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}
