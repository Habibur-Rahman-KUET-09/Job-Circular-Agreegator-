import 'package:firebase_auth/firebase_auth.dart';

import '../l10n/strings.dart';

/// A localized message for a Firebase Auth failure.
String authErrorMessage(Strings s, Object error) {
  if (error is! FirebaseAuthException) return s.loginErrorGeneric;
  switch (error.code) {
    case 'invalid-email':
      return s.loginErrorInvalidEmail;
    case 'user-disabled':
      return s.loginErrorUserDisabled;
    case 'user-not-found':
      return s.loginErrorUserNotFound;
    case 'invalid-credential':
    case 'wrong-password':
      return s.loginErrorWrongPassword;
    case 'email-already-in-use':
      return s.loginErrorEmailInUse;
    case 'weak-password':
      return s.loginErrorWeakPassword;
    case 'network-request-failed':
      return s.loginErrorNetwork;
    case 'too-many-requests':
      return s.loginErrorTooManyRequests;
    case 'requires-recent-login':
      return s.reloginRequired;
    case 'missing-google-id-token':
      return s.loginErrorMissingGoogleToken;
    case 'no-current-user':
      return s.loginErrorNoCurrentUser;
    case 'missing-password':
      return s.loginErrorMissingPassword;
    default:
      return error.message ?? s.loginErrorGeneric;
  }
}
