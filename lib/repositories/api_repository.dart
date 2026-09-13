import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract class AuthRepository {
  Future<AuthCredential> handleGoogleSignIn(FirebaseAuth auth);
  Future<User> convertCredentialToUser(
      FirebaseAuth auth, AuthCredential credential);
  Future<AuthCredential> handleFacebookSignIn(FirebaseAuth auth);
  Future<String> getToken(User user);
}

/// Raised when a Facebook login request completes without a usable token.
///
/// `flutter_facebook_auth` reports the ordinary "no token for you" outcomes
/// (cancelled, failed, another login already in flight) through
/// [LoginResult.status] rather than by throwing, so the repository has to turn
/// them into an error itself. Without this the null [LoginResult.accessToken]
/// would reach `FacebookAuthProvider.credential` and either blow up on the
/// null check or, worse, be coerced into a credential that fails later at
/// `signInWithCredential` with a message that points nowhere near the real
/// cause.
class FacebookSignInException implements Exception {
  const FacebookSignInException(this.status, [this.message]);

  final LoginStatus status;
  final String? message;

  @override
  String toString() => 'Exception: Facebook sign-in produced no access token'
      ' (status: ${status.name}'
      '${message == null ? '' : ', message: $message'})';
}

class ApiRepository extends AuthRepository {
  // NOTE: not migrated in this change (out of scope, tracked by the Firebase
  // upgrade work). This is still the google_sign_in v5/6 call shape and does not
  // compile against the v7 API that is currently pinned in pubspec.yaml
  // (v7 has no `GoogleSignIn()` constructor and no `signIn()`; it uses
  // `GoogleSignIn.instance.initialize()` + `authenticate()`). Migrating it here
  // would mean picking a serverClientId/`clientId` source, which belongs with
  // centralising the app's Firebase config rather than with the Facebook swap.
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

  /// Signs the user in with Facebook and returns the matching Firebase
  /// credential.
  ///
  /// Migrated off the previously-used discontinued Facebook login plugin to its
  /// maintained successor `flutter_facebook_auth`. Two shapes changed:
  ///
  /// * The old `logIn()` returned a result whose `accessToken` was read
  ///   unconditionally (crashing on cancel); the new `login()` returns a
  ///   [LoginResult] carrying a [LoginStatus] plus a *nullable* token, which
  ///   is checked here.
  /// * The token type changed from the old `FacebookAccessToken.token` to
  ///   [AccessToken.tokenString], which is what
  ///   `FacebookAuthProvider.credential` is now built from.
  ///
  /// The old forced-embedded-web-view `loginBehavior` is deliberately dropped
  /// rather than translated: it existed only to work around a deadlock in the
  /// discontinued package's *native* login activity. That package is gone, and
  /// the successor's own default (`FacebookAuth.login` defaults to
  /// `LoginBehavior.nativeWithFallback`) uses the supported path, so carrying
  /// the override over would re-impose a workaround whose reason no longer
  /// exists. It is also the direction Facebook's own guidance points: an
  /// embedded web view is no longer a supported way to run their login, while a
  /// native/system-browser flow is. If a specific behavior is ever wanted it is
  /// a single `loginBehavior:` argument away.
  ///
  /// `test/repositories/facebook_sign_in_test.dart` pins this down: it records
  /// the behavior the app actually sends and asserts it is the package default
  /// and not the web view.
  @override
  Future<AuthCredential> handleFacebookSignIn(FirebaseAuth auth) async {
    final LoginResult result = await FacebookAuth.instance.login(
      // Same scope set the old code requested; keeping it identical avoids this
      // migration silently widening what users are asked to consent to.
      permissions: const ['public_profile'],
    );

    final AccessToken? token = result.accessToken;
    if (result.status != LoginStatus.success || token == null) {
      throw FacebookSignInException(result.status, result.message);
    }

    return FacebookAuthProvider.credential(token.tokenString);
  }

  /// Exchanges [credential] for a signed-in [User].
  ///
  /// `signInWithCredential` types its `user` as nullable (it can come back
  /// empty when the credential is rejected in a way that does not throw), so
  /// the null case is turned into an explicit error rather than being forced
  /// through with `!`.
  @override
  Future<User> convertCredentialToUser(
      FirebaseAuth auth, AuthCredential credential) async {
    final UserCredential userCredential =
        await auth.signInWithCredential(credential);
    final User? user = userCredential.user;
    if (user == null) {
      throw StateError(
          'Firebase sign-in with ${credential.providerId} returned no user');
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
