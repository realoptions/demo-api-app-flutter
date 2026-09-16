import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';
import 'package:realoptions/repositories/api_repository.dart';

/// Test double for [AuthRepository].
///
/// The Google path drives a real `MockGoogleSignIn` object and then really
/// exchanges the resulting credential with the injected Firebase fake, so what
/// the bloc receives is a genuine sign-in shaped by `firebase_auth` rather than
/// a hand-rolled stand-in that could drift from what production produces.
///
/// Note which transport this mirrors: the **native** one (google_sign_in -> ID
/// token -> `signInWithCredential`), because tests run on the Dart VM. It is
/// deliberately not a mirror of the web popup transport — that path is covered
/// against the real `ApiRepository` in
/// `test/repositories/api_repository_web_test.dart`, since faking it here is
/// exactly what let it ship broken.
class MockApiRepository extends AuthRepository {
  @override
  Future<User> handleGoogleSignIn(FirebaseAuth auth) async {
    final MockGoogleSignIn googleSignIn = MockGoogleSignIn();
    // google_sign_in v7 replaced signIn() with authenticate(), and the
    // account's `authentication` is a synchronous getter rather than a future.
    final GoogleSignInAccount account = await googleSignIn.authenticate();
    final GoogleSignInAuthentication googleAuth = account.authentication;
    final String? idToken = googleAuth.idToken;
    if (idToken == null) {
      throw StateError('MockGoogleSignIn returned no id token');
    }
    final UserCredential userCredential = await auth
        .signInWithCredential(GoogleAuthProvider.credential(idToken: idToken));
    final User? user = userCredential.user;
    if (user == null) {
      throw StateError('MockGoogleSignIn sign-in produced no user');
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
