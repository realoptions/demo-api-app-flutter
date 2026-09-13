import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:realoptions/firebase_options.dart';

abstract class AuthRepository {
  Future<AuthCredential> handleGoogleSignIn(FirebaseAuth auth);
  Future<User> convertCredentialToUser(
      FirebaseAuth auth, AuthCredential credential);
  Future<AuthCredential> handleFacebookSignIn(FirebaseAuth auth);

  /// Signs in without a social identity provider, for the hosted demo.
  ///
  /// Returns the signed-in [User] rather than an [AuthCredential] because
  /// anonymous auth has no external credential to exchange: `signInAnonymously`
  /// yields the user directly, so the `convertCredentialToUser` step the social
  /// paths need does not exist here.
  Future<User> signInAsGuest(FirebaseAuth auth);

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
  /// google_sign_in v7 exposes a singleton that must be initialised exactly once,
  /// with its future awaited, before any other call on it. The v5/v6 shape this
  /// file used — construct a `GoogleSignIn()` per sign-in — no longer exists, so
  /// the one-shot lives here and is shared across attempts.
  ///
  /// Memoised rather than done in `main()` so that a build which never reaches
  /// Google sign-in never pays for it, and so the guarantee lives next to the
  /// only caller.
  Future<void>? _googleSignInInit;

  Future<void> _ensureGoogleSignInInitialized() {
    return _googleSignInInit ??= GoogleSignIn.instance.initialize(
      // The web OAuth client ID comes from the centralised Firebase web config
      // (lib/firebase_options.dart), not from the `google-signin-client_id`
      // meta tag it used to be read out of. Null off the web, where the
      // platform configuration files supply it.
      clientId: kIsWeb ? FirebaseConfig.googleWebClientId : null,
    );
  }

  @override
  Future<AuthCredential> handleGoogleSignIn(FirebaseAuth auth) async {
    await _ensureGoogleSignInInitialized();
    // v7 replaced `signIn()` with `authenticate()`, and the account's
    // `authentication` is a synchronous getter that now carries only an
    // `idToken` (the access token moved to a separate client-authorization
    // call the Firebase exchange does not need).
    final GoogleSignInAccount googleUser =
        await GoogleSignIn.instance.authenticate();
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final String? idToken = googleAuth.idToken;
    if (idToken == null) {
      throw StateError('Google sign-in returned no ID token');
    }
    return GoogleAuthProvider.credential(idToken: idToken);
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

  /// Signs in anonymously so the hosted demo can be used without a social
  /// account.
  ///
  /// An existing session is reused rather than signed in again.
  ///
  /// For an anonymous user that is a correctness point: `signInAnonymously`
  /// creates a *new* Firebase user every time it is called on a signed-out
  /// client, so re-entering the demo would otherwise mint a fresh uid per visit
  /// and pile up throwaway accounts on the project.
  ///
  /// For a non-anonymous (socially signed-in) user it is a safety point: "continue
  /// as guest" is not a sign-out, and silently replacing a signed-in social
  /// session with an anonymous one would be a surprising thing for that button to
  /// do. The existing session is returned untouched.
  @override
  Future<User> signInAsGuest(FirebaseAuth auth) async {
    final User? current = auth.currentUser;
    if (current != null) {
      return current;
    }
    final UserCredential userCredential = await auth.signInAnonymously();
    final User? user = userCredential.user;
    if (user == null) {
      throw StateError('Anonymous sign-in returned no user');
    }
    return user;
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
