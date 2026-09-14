// Covers the app's Facebook sign-in path against the replacement plugin.
//
// The plugin's own platform interface is swapped for _FakeFacebookAuthPlatform
// so the *real* ApiRepository.handleFacebookSignIn runs - no device, no
// Facebook app, no network round-trip. Assertions are about what the app
// *asked for* (scope set, login behaviour) and not only about what came back:
// those two things are exactly what changed in the plugin swap, and the point
// is that the forced-web-view workaround is gone rather than having been
// silently translated into something else.
//
// The shape of the credentials produced by the shared test double used by the
// bloc tests is pinned separately in `mock_auth_repository_test.dart`; this
// file is about the production path, not the double.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_facebook_auth_platform_interface/flutter_facebook_auth_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/repositories/api_repository.dart';

/// A stand-in for the Facebook SDK.
///
/// Recorded so the assertions are about what the app *asked for* (scope set,
/// login behaviour) and not just about what came back.
class _FakeFacebookAuthPlatform extends FacebookAuthPlatform {
  _FakeFacebookAuthPlatform();

  /// Canned results, handed out one per `login()` call.
  final List<LoginResult> queued = <LoginResult>[];

  final List<List<String>> requestedPermissions = <List<String>>[];
  final List<LoginBehavior> requestedBehaviors = <LoginBehavior>[];
  int loginCalls = 0;

  void queueResult(LoginResult result) => queued.add(result);

  @override
  Future<LoginResult> login({
    List<String> permissions = const ['email', 'public_profile'],
    LoginBehavior loginBehavior = LoginBehavior.dialogOnly,
    LoginTracking loginTracking = LoginTracking.enabled,
    String? nonce,
  }) async {
    loginCalls++;
    requestedPermissions.add(permissions);
    requestedBehaviors.add(loginBehavior);
    if (queued.isEmpty) {
      throw StateError(
          'test did not queue a LoginResult for login #$loginCalls');
    }
    return queued.removeAt(0);
  }

  // Members below are not reachable from ApiRepository; they exist because the
  // platform interface declares them. They fail loudly rather than quietly
  // returning something a test might accidentally depend on.
  @override
  Future<void> webAndDesktopInitialize({
    required String appId,
    required bool cookie,
    required bool xfbml,
    required String version,
  }) async =>
      throw UnimplementedError('not used by ApiRepository');

  @override
  bool get isWebSdkInitialized =>
      throw UnimplementedError('not used by ApiRepository');

  @override
  Future<LoginResult> expressLogin() =>
      throw UnimplementedError('not used by ApiRepository');

  @override
  Future<Map<String, dynamic>> getUserData(
          {String fields = "name,email,picture.width(200)"}) =>
      throw UnimplementedError('not used by ApiRepository');

  @override
  Future<void> autoLogAppEventsEnabled(bool enabled) =>
      throw UnimplementedError('not used by ApiRepository');

  @override
  Future<bool> get isAutoLogAppEventsEnabled =>
      throw UnimplementedError('not used by ApiRepository');

  @override
  Future<void> logOut() =>
      throw UnimplementedError('not used by ApiRepository');

  @override
  Future<AccessToken?> get accessToken =>
      throw UnimplementedError('not used by ApiRepository');
}

/// A classic (non-limited) Facebook token.
///
/// `authenticationToken` is set to a deliberately different value from
/// `tokenString` so a test can prove the credential is built from the access
/// token and not from some other field on the new token type.
ClassicToken _classicToken(String tokenString) => ClassicToken(
      tokenString: tokenString,
      userId: '10101010101010101',
      applicationId: '1234567890',
      expires: DateTime.utc(2030, 1, 1),
      grantedPermissions: const ['public_profile'],
      declinedPermissions: const <String>[],
      authenticationToken: 'SHOULD-NOT-BE-USED',
    );

void main() {
  late _FakeFacebookAuthPlatform platform;
  late FirebaseAuth auth;
  late ApiRepository repo;

  setUp(() {
    platform = _FakeFacebookAuthPlatform();
    FacebookAuthPlatform.instance = platform;
    // FacebookAuth keeps the platform instance in a field captured at
    // construction, so rebind it here; otherwise the first fake installed
    // would be reused by every later test in this file.
    FacebookAuth.instance = FacebookAuth.getInstance();
    auth = MockFirebaseAuth(signedIn: true);
    repo = ApiRepository();
  });

  group('handleFacebookSignIn', () {
    test('builds a Facebook credential from the new token type', () async {
      platform.queueResult(
        LoginResult(
          status: LoginStatus.success,
          accessToken: _classicToken('fb-access-token-123'),
        ),
      );

      final AuthCredential credential = await repo.handleFacebookSignIn(auth);

      expect(credential.providerId, 'facebook.com');
      // The value that reached Firebase is the token's `tokenString`, not some
      // other field on the new AccessToken type.
      expect(credential.accessToken, 'fb-access-token-123');
      expect(platform.loginCalls, 1);
    });

    test('requests the same scope set the old package requested', () async {
      platform.queueResult(
        LoginResult(
          status: LoginStatus.success,
          accessToken: _classicToken('t'),
        ),
      );

      await repo.handleFacebookSignIn(auth);

      // The plugin's own default is ['email', 'public_profile']; the app asked
      // for public_profile only before the swap, so a migration that quietly
      // started asking for email would be a user-visible consent change.
      expect(platform.requestedPermissions.single, ['public_profile']);
    });

    test('does not force a web-view login behavior', () async {
      platform.queueResult(
        LoginResult(
          status: LoginStatus.success,
          accessToken: _classicToken('t'),
        ),
      );

      await repo.handleFacebookSignIn(auth);

      // The old code set FacebookLoginBehavior.webViewOnly to dodge
      // roughike/flutter_facebook_login#210, a deadlock in that package's
      // native login activity. Nothing should be overriding the replacement's
      // default now that the bug it worked around cannot occur.
      //
      // Note the value recorded here: `FacebookAuth.login`'s own default is
      // `nativeWithFallback` (the platform interface declares `dialogOnly`, but
      // that never applies when going through the `FacebookAuth` wrapper, which
      // always passes its own default down). Asserting equality against the
      // wrapper default is what proves nothing is being overridden here, and the
      // explicit webOnly check documents the thing that had to go away.
      expect(
          platform.requestedBehaviors.single, LoginBehavior.nativeWithFallback);
      expect(platform.requestedBehaviors.single, isNot(LoginBehavior.webOnly));
    });

    test('surfaces a cancellation as an error instead of a null token',
        () async {
      platform.queueResult(LoginResult(status: LoginStatus.cancelled));

      Object? thrown;
      try {
        await repo.handleFacebookSignIn(auth);
      } catch (e) {
        thrown = e;
      }

      // A cancelled login used to fall straight through to
      // `result.accessToken.token` and throw a null-check error naming neither
      // Facebook nor the reason.
      expect(thrown, isA<FacebookSignInException>());
      expect((thrown as FacebookSignInException).status, LoginStatus.cancelled);
      expect(thrown.toString(), contains('cancelled'));
    });

    test('keeps the plugin failure message on the error', () async {
      platform.queueResult(LoginResult(
        status: LoginStatus.failed,
        message: 'invalid_app_id',
      ));

      Object? thrown;
      try {
        await repo.handleFacebookSignIn(auth);
      } catch (e) {
        thrown = e;
      }

      expect(thrown, isA<FacebookSignInException>());
      final FacebookSignInException e = thrown as FacebookSignInException;
      expect(e.status, LoginStatus.failed);
      expect(e.message, 'invalid_app_id');
      expect(e.toString(), contains('invalid_app_id'));
    });

    test('treats a login already in progress as a failure', () async {
      platform
          .queueResult(LoginResult(status: LoginStatus.operationInProgress));

      expect(repo.handleFacebookSignIn(auth),
          throwsA(isA<FacebookSignInException>()));
    });

    test('rejects a success result that carries no token', () async {
      // Defensive: the status and the nullable token are separate fields on
      // LoginResult, so an inconsistent platform response must not become a
      // credential built from null.
      platform.queueResult(
          LoginResult(status: LoginStatus.success, accessToken: null));

      expect(repo.handleFacebookSignIn(auth),
          throwsA(isA<FacebookSignInException>()));
    });
  });
}
