import 'package:realoptions/repositories/api_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';

class MockApiRepository extends AuthRepository {
  @override
  Future<AuthCredential> handleGoogleSignIn(FirebaseAuth auth) async {
    final googleSignIn = MockGoogleSignIn();
    final signinAccount = await googleSignIn.signIn();
    final googleAuth = await signinAccount.authentication;
    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return Future<AuthCredential>.value(credential);
  }

  //duplicate, but need this method in order to satisfy abstract class
  @override
  Future<AuthCredential> handleFacebookSignIn(FirebaseAuth auth) async {
    final googleSignIn = MockGoogleSignIn();
    final signinAccount = await googleSignIn.signIn();
    final googleAuth = await signinAccount.authentication;
    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return Future<AuthCredential>.value(credential);
  }

  @override
  Future<FirebaseUser> convertCredentialToUser(
      FirebaseAuth auth, AuthCredential credential) async {
    return (await auth.signInWithCredential(credential)).user;
  }

  @override
  Future<String> getToken(FirebaseUser user) {
    return user.getIdToken().then((idToken) {
      return idToken.token;
    });
  }
}
