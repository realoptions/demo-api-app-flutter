import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';

Future<FirebaseUser> handleGoogleSignIn(FirebaseAuth auth) async {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
  final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

  final AuthCredential credential = GoogleAuthProvider.getCredential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  final FirebaseUser user = (await auth.signInWithCredential(credential)).user;
  return user;
}

Future<FirebaseUser> handleFacebookSignIn(FirebaseAuth auth) async {
  final FacebookLogin facebookLogin = FacebookLogin();
  // https://github.com/roughike/flutter_facebook_login/issues/210
  facebookLogin.loginBehavior = FacebookLoginBehavior.webViewOnly;
  final FacebookLoginResult result =
      await facebookLogin.logIn(<String>['public_profile']);
  if (result.accessToken != null) {
    final AuthResult authResult = await auth.signInWithCredential(
      FacebookAuthProvider.getCredential(accessToken: result.accessToken.token),
    );
    return authResult.user;
  }
  return null;
}
