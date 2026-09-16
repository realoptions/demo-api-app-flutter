import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:realoptions/firebase_options.dart';

/// The identity-provider operations the app needs.
///
/// Google is the only provider implemented. Facebook was removed: the hosted web
/// build has no Facebook app id anywhere — not in Dart, not in
/// `web/index.html.template`, not in the deployed bundle — so the Facebook
/// button could never complete a login. Anonymous/guest access was removed
/// because the hosting project does not permit it.
abstract class AuthRepository {
  Future<AuthCredential> handleGoogleSignIn(FirebaseAuth auth);
  Future<User> convertCredentialToUser(
      FirebaseAuth auth, AuthCredential credential);

  Future<String> getToken(User user);
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
