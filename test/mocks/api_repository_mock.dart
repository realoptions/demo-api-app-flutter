import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';
import 'package:realoptions/repositories/api_repository.dart';

/// Test double for [AuthRepository].
///
/// The Google path drives a real `MockGoogleSignIn` object. The Facebook path
/// builds a genuine Facebook-shaped [AuthCredential] straight from
/// `firebase_auth`'s [FacebookAuthProvider] instead of copying the Google
/// result: a fake that hands back Google credentials would silently turn any
/// "signed in with Facebook" assertion into a tautology.
///
/// Building the credential from `firebase_auth` also means this fake does not
/// depend on a Facebook login plugin at all, so the Facebook path keeps being
/// testable across the plugin swap and needs no device, Facebook app or network
/// round-trip. The replacement plugin itself is covered separately by
/// `test/repositories/facebook_sign_in_test.dart`, which swaps the plugin's
/// platform interface instead of bypassing it.
class MockApiRepository extends AuthRepository {
  /// Access token reported by the fake Facebook sign-in path.
  ///
  /// Deliberately a Facebook-looking value rather than a shared fake token: tests
  /// can assert it is the exact string that reaches
  /// [FacebookAuthProvider.credential].
  static const String facebookAccessToken = "fake_facebook_access_token";

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
  Future<AuthCredential> handleFacebookSignIn(FirebaseAuth auth) async {
    // FacebookAuthProvider ships with firebase_auth, so no Facebook login plugin
    // (and no network round-trip) is needed to produce a real Facebook
    // credential: the resulting credential carries providerId 'facebook.com',
    // exactly like the one the production path builds from the plugin's token.
    return FacebookAuthProvider.credential(facebookAccessToken);
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
