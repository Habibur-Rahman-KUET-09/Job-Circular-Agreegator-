import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { user, recruiter, moderator, admin }

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // Get current user's role from custom claims
  Future<UserRole?> getCurrentUserRole() async {
    try {
      await _auth.currentUser?.reload();
      final token = await _auth.currentUser?.getIdTokenResult();
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

  // Get current user's company (for recruiters)
  Future<String?> getCurrentUserCompany() async {
    try {
      await _auth.currentUser?.reload();
      final token = await _auth.currentUser?.getIdTokenResult();
      return token?.claims?['company'] as String?;
    } catch (e) {
      return null;
    }
  }

  // Sign up with email and password
  Future<User?> signUpWithEmail(String email, String password, String fullName) async {
    try {
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(fullName);

      // Create user profile in Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'fullName': fullName,
        'createdAt': DateTime.now().toIso8601String(),
        'notificationsEnabled': true,
        'preferredLanguage': 'bn',
      }, SetOptions(merge: true));

      return credential.user;
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign in with email and password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _getGoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Create user profile if doesn't exist
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      if (!userDoc.exists) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': userCredential.user!.email,
          'fullName': userCredential.user!.displayName ?? 'User',
          'profilePhotoUrl': userCredential.user!.photoURL,
          'createdAt': DateTime.now().toIso8601String(),
          'notificationsEnabled': true,
          'preferredLanguage': 'bn',
        });
      }

      return userCredential.user;
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }

  // Reset password with code
  Future<void> resetPasswordWithCode(String code, String newPassword) async {
    try {
      await _auth.confirmPasswordReset(code: code, newPassword: newPassword);
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _getGoogleSignIn().signOut();
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
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

  // Check if email exists
  Future<bool> doesEmailExist(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      return false;
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

  // Helper to get Google SignIn instance with default config
  // In production, configure this with your Google OAuth credentials
  dynamic _getGoogleSignIn() {
    // This is a placeholder - implement based on your google_sign_in package usage
    // In the actual implementation, this would use google_sign_in package
    return null;
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
