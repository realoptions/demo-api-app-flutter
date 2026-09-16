import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';
import 'package:realoptions/repositories/api_repository.dart';

/// Test double for [AuthRepository].
///
/// The Google path drives a real `MockGoogleSignIn` object and returns the
/// `firebase_auth` credential built from it, so what the bloc receives is a
/// genuine Google-shaped credential (providerId `google.com`) rather than a
/// hand-rolled stand-in that could drift from what production produces.
class MockApiRepository extends AuthRepository {
  @override
  Future<AuthCredential> handleGoogleSignIn(FirebaseAuth auth) async {
    final MockGoogleSignIn googleSignIn = MockGoogleSignIn();
    // google_sign_in v7 replaced signIn() with authenticate(), and the
    // account's `authentication` is a synchronous getter rather than a future.
    final GoogleSignInAccount account = await googleSignIn.authenticate();
    final GoogleSignInAuthentication googleAuth = account.authentication;
    final String? idToken = googleAuth.idToken;
    if (idToken == null) {
      throw StateError('MockGoogleSignIn returned no id token');
    }
    return GoogleAuthProvider.credential(idToken: idToken);
  }

  @override
  Future<User> convertCredentialToUser(
      FirebaseAuth auth, AuthCredential credential) async {
    final UserCredential userCredential =
        await auth.signInWithCredential(credential);
    final User? user = userCredential.user;
    if (user == null) {
      throw StateError(
          'signInWithCredential(${credential.providerId}) returned no user');
    }
    return user;
  }

  @override
  Future<String> getToken(User user) async {
    final String? token = await user.getIdToken();
    if (token == null) {
      throw StateError('Could not obtain an ID token for ${user.uid}');
    }
    return token;
  }
}
