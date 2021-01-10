import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:meta/meta.dart';

class ApiRepository {
  //final ApiClient apiClient;

  //ApiRepository();
  //final FirebaseAuth firebaseAuth;
  //ApiRepository({@required this.firebaseAuth});
  Future<AuthCredential> handleGoogleSignIn(FirebaseAuth auth) async {
    final GoogleSignIn _googleSignIn = GoogleSignIn();
    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return credential;
    //setBusy();
    //final FirebaseUser user = (await auth.signInWithCredential(credential)).user;
    //return user;
  }

  Future<FirebaseUser> convertCredentialToUser(
      FirebaseAuth auth, AuthCredential credential) async {
    return (await auth.signInWithCredential(credential)).user;
  }

  Future<FacebookLoginResult> handleFacebookSignIn(FirebaseAuth auth) async {
    final FacebookLogin facebookLogin = FacebookLogin();
    // https://github.com/roughike/flutter_facebook_login/issues/210
    facebookLogin.loginBehavior = FacebookLoginBehavior.webViewOnly;
    final FacebookLoginResult result =
        await facebookLogin.logIn(<String>['public_profile']);

    return result;

    /*if (result.accessToken != null) {
    setBusy();
    final AuthResult authResult = await auth.signInWithCredential(
      FacebookAuthProvider.getCredential(accessToken: result.accessToken.token),
    );
    return authResult.user;
  }
  return null;*/
  }

  Future<FirebaseUser> convertFacebookToUser(
      FirebaseAuth auth, FacebookLoginResult facebookLogin) async {
    return (await auth.signInWithCredential(
      FacebookAuthProvider.getCredential(
          accessToken: facebookLogin.accessToken.token),
    ))
        .user;
  }

  Future<String> getToken(FirebaseUser user) {
    return user.getIdToken().then((idToken) {
      return idToken.token;
    });
  }
}
