import 'package:realoptions/repositories/api_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';

/// Test double for [AuthRepository].
///
/// The Google path drives a real `MockGoogleSignIn` object. The Facebook path
/// builds a genuine Facebook-shaped [AuthCredential] straight from
/// `firebase_auth`'s [FacebookAuthProvider] instead of copying the Google
/// result: a fake that hands back Google credentials would silently turn any
/// "signed in with Facebook" assertion into a tautology.
///
/// Building the credential from `firebase_auth` also means this fake does not
/// depend on `flutter_facebook_login` (a discontinued package that is slated for
/// replacement), so the Facebook path keeps being testable across that
/// migration.
class MockApiRepository extends AuthRepository {
  /// Access token reported by the fake Facebook sign-in path.
  static const String facebookAccessToken = "fake_facebook_access_token";

  @override
  Future<AuthCredential> handleGoogleSignIn(FirebaseAuth auth) async {
    final googleSignIn = MockGoogleSignIn();
    final signinAccount = await googleSignIn.signIn();
    final googleAuth = await signinAccount.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return Future<AuthCredential>.value(credential);
  }

  @override
  Future<AuthCredential> handleFacebookSignIn(FirebaseAuth auth) async {
    // FacebookAuthProvider ships with firebase_auth, so no Facebook login plugin
    // (and no network round-trip) is needed to produce a real Facebook credential.
    return FacebookAuthProvider.credential(facebookAccessToken);
  }

  @override
  Future<User> convertCredentialToUser(
      FirebaseAuth auth, AuthCredential credential) async {
    return (await auth.signInWithCredential(credential)).user;
  }

  @override
  Future<String> getToken(User user) {
    return user.getIdToken().then((token) {
      return token;
    });
  }
}
