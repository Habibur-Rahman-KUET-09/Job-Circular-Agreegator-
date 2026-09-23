import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum UserRole { user, recruiter, moderator, admin }

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _googleInitialized = false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserRole?> getCurrentUserRole() async {
    try {
      final token = await _auth.currentUser?.getIdTokenResult(true);
      final role = token?.claims?['role'] as String?;
      if (role != null) {
        return UserRole.values.firstWhere(
          (r) => r.name == role,
          orElse: () => UserRole.user,
        );
      }
      return UserRole.user;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getCurrentUserCompany() async {
    try {
      await _auth.currentUser?.reload();
      final token = await _auth.currentUser?.getIdTokenResult();
      return token?.claims?['company'] as String?;
    } catch (e) {
      return null;
    }
  }

  // Auth errors are rethrown as FirebaseAuthException so LoginScreen can map
  // e.code to a localized message.
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    if (fullName != null && fullName.isNotEmpty) {
      await user.updateDisplayName(fullName);
    }
    await _createProfileIfMissing(user, fullName: fullName);
    return user;
  }

  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  Future<User?> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn.instance;
    if (!_googleInitialized) {
      await googleSignIn.initialize();
      _googleInitialized = true;
    }
    final account = await googleSignIn.authenticate();
    final credential = GoogleAuthProvider.credential(
      idToken: account.authentication.idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;
    await _createProfileIfMissing(user);
    return user;
  }

  Future<void> _createProfileIfMissing(User user, {String? fullName}) async {
    final doc = _firestore.collection('users').doc(user.uid);
    if ((await doc.get()).exists) return;
    await doc.set({
      'userId': user.uid,
      'email': user.email,
      'fullName': fullName ?? user.displayName ?? 'User',
      'profilePhotoUrl': user.photoURL,
      'createdAt': DateTime.now().toIso8601String(),
      'notificationsEnabled': true,
      'preferredLanguage': 'bn',
    });
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> resetPasswordWithCode(String code, String newPassword) {
    return _auth.confirmPasswordReset(code: code, newPassword: newPassword);
  }

  Future<void> signOut() async {
    if (_googleInitialized) {
      await GoogleSignIn.instance.signOut();
    }
    await _auth.signOut();
  }

  // Set custom claims (admin operation - typically done via Cloud Function)
  // For testing/development, this is a placeholder - in production use Cloud Functions
  Future<void> setUserRole(String uid, UserRole role, {String? company}) async {
    try {
      // In production, call a Cloud Function to set custom claims
      // This requires Admin SDK which is not available client-side
      // For now, we store role in user profile for reference
      final Map<String, dynamic> data = {'role': role.name};
      if (company != null) data['company'] = company;

      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw Exception('Failed to set user role: $e');
    }
  }

  // Delete account (permanent)
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user signed in');

      // Delete user profile from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete Firebase auth user
      await user.delete();
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user signed in');

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      await _auth.currentUser?.reload();
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Change email
  Future<void> changeEmail(String newEmail) async {
    try {
      await _auth.currentUser?.verifyBeforeUpdateEmail(newEmail);
    } catch (e) {
      throw Exception('Failed to change email: $e');
    }
  }

  // Change password (user must be recently authenticated)
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user signed in');

      // Re-authenticate user first
      if (user.email != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);
      }

      // Change password
      await user.updatePassword(newPassword);
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }
}
