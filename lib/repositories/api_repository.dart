import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';

abstract class AuthRepository {
  Future<AuthCredential> handleGoogleSignIn(FirebaseAuth auth);
  Future<User> convertCredentialToUser(
      FirebaseAuth auth, AuthCredential credential);
  Future<AuthCredential> handleFacebookSignIn(FirebaseAuth auth);
  Future<String> getToken(User user);
}

class ApiRepository extends AuthRepository {
  @override
  Future<AuthCredential> handleGoogleSignIn(FirebaseAuth auth) async {
    final GoogleSignIn _googleSignIn = GoogleSignIn();
    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return credential;
  }

  @override
  Future<AuthCredential> handleFacebookSignIn(FirebaseAuth auth) async {
    final FacebookLogin facebookLogin = FacebookLogin();
    // https://github.com/roughike/flutter_facebook_login/issues/210
    facebookLogin.loginBehavior = FacebookLoginBehavior.webViewOnly;
    final FacebookLoginResult result =
        await facebookLogin.logIn(<String>['public_profile']);
    final AuthCredential credential =
        FacebookAuthProvider.credential(result.accessToken.token);
    return credential;
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
