import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

/// The identity-provider operations the app needs.
///
/// Google is the only provider implemented. Facebook was removed: the hosted web
/// build has no Facebook app id anywhere — not in Dart, not in
/// `web/index.html.template`, not in the deployed bundle — so the Facebook
/// button could never complete a login. Anonymous/guest access was removed
/// because the hosting project does not permit it.
abstract class AuthRepository {
  /// Signs the user in with Google and returns the Firebase [User] it produced.
  ///
  /// This returns the [User] rather than an [AuthCredential] because the two
  /// platforms reach that user in a different number of steps. Natively the app
  /// obtains a Google credential and then exchanges it with Firebase; on the web
  /// the popup *is* the exchange — it signs this client in and hands back the
  /// user, so no credential is left over to hand to a caller. An interface that
  /// returned a credential would force the caller to run a *second* sign-in to
  /// get a user, which on the web means a second popup.
  ///
  /// Anything that goes wrong — a dismissed or blocked popup, a rejected
  /// credential, no network — is thrown to the caller rather than swallowed, so
  /// the sign-in screen can say why.
  Future<User> handleGoogleSignIn(FirebaseAuth auth);

  Future<String> getToken(User user);
}

class ApiRepository extends AuthRepository {
  /// Selects the sign-in transport. Defaults to the platform the code is
  /// actually running on.
  ///
  /// Injected rather than read from [kIsWeb] at the call site so the web branch
  /// can be exercised by a test running on the Dart VM, where [kIsWeb] is
  /// false. Before this seam existed, the branch the shipped app takes was
  /// invisible to the suite: every test injected a mocked [AuthRepository], so
  /// the real web path stayed untested while it was, in fact, completely broken.
  ApiRepository({bool? isWeb}) : _isWeb = isWeb ?? kIsWeb;

  final bool _isWeb;

  @override
  Future<User> handleGoogleSignIn(FirebaseAuth auth) =>
      _isWeb ? _signInWithPopup(auth) : _signInWithGoogleNative(auth);

  /// Web: let Firebase Auth run the Google popup end to end.
  ///
  /// `google_sign_in` cannot do this on the web. Its web implementation reports
  /// `supportsAuthenticate() == false` and `authenticate()` throws
  /// `UnimplementedError: authenticate is not supported on the web` — which is
  /// exactly what every sign-in attempt in the hosted build did until this
  /// method replaced it. The popup comes from `firebase_auth_web` instead,
  /// configured by the Firebase web options in `lib/firebase_options.dart`.
  ///
  /// The app needs no Google OAuth client ID for this: the Google provider is
  /// configured on the Firebase project, and the popup round-trips through
  /// `authDomain`. A blocked or dismissed popup throws a [FirebaseAuthException]
  /// (`popup_blocked_by_browser`, `popup_closed_by_user`, …) which propagates.
  Future<User> _signInWithPopup(FirebaseAuth auth) async {
    final UserCredential userCredential =
        await auth.signInWithPopup(GoogleAuthProvider());
    final User? user = userCredential.user;
    if (user == null) {
      throw StateError('Google sign-in popup completed with no user');
    }
    return user;
  }

  /// Android/iOS: `google_sign_in` v7 -> ID token -> Firebase credential -> user.
  ///
  /// Kept because `signInWithPopup` is a web-only capability; off the web the
  /// native SDK is the only way in. The steps the web popup collapses into one
  /// call are spelled out here: v7 replaced `signIn()` with `authenticate()`,
  /// and the account's `authentication` is a synchronous getter that now
  /// carries only an `idToken` (the access token moved to a separate
  /// client-authorization call the Firebase exchange does not need).
  Future<User> _signInWithGoogleNative(FirebaseAuth auth) async {
    await _ensureGoogleSignInInitialized();
    final GoogleSignInAccount googleUser =
        await GoogleSignIn.instance.authenticate();
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final String? idToken = googleAuth.idToken;
    if (idToken == null) {
      throw StateError('Google sign-in returned no ID token');
    }
    return _userFromCredential(
        auth, GoogleAuthProvider.credential(idToken: idToken));
  }

  /// google_sign_in v7 exposes a singleton that must be initialised exactly once,
  /// with its future awaited, before any other call on it. The v5/v6 shape —
  /// construct a `GoogleSignIn()` per sign-in — no longer exists, so the one-shot
  /// lives here and is shared across attempts.
  ///
  /// Memoised rather than done in `main()` so that a build which never reaches
  /// Google sign-in never pays for it, and so the guarantee lives next to the
  /// only caller. The web no longer reaches it at all: the client ID it used to
  /// pass on the way in was only ever needed by the `google_sign_in` web flow.
  Future<void>? _googleSignInInit;

  Future<void> _ensureGoogleSignInInitialized() {
    // Off the web the client ID comes from the platform configuration files
    // (android/app/google-services.json and the iOS Info.plist), so it is not
    // passed here.
    return _googleSignInInit ??= GoogleSignIn.instance.initialize();
  }

  /// Exchanges [credential] for a signed-in [User].
  ///
  /// `signInWithCredential` types its `user` as nullable (it can come back
  /// empty when the credential is rejected in a way that does not throw), so
  /// the null case is turned into an explicit error rather than being forced
  /// through with `!`.
  Future<User> _userFromCredential(
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
