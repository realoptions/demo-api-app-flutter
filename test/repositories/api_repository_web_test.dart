import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/repositories/api_repository.dart';

/// The web sign-in path, driven against the **real** [ApiRepository].
///
/// This file exists because the shipping target had no coverage of itself. The
/// hosted web build obtained its Google sign-in from
/// `GoogleSignIn.instance.authenticate()`, which `google_sign_in_web` refuses
/// outright (`supportsAuthenticate() == false`, `authenticate()` throws
/// `UnimplementedError: authenticate is not supported on the web`), so *every*
/// sign-in tap in the deployed app failed — while the whole suite stayed green,
/// because every test injected a mocked [AuthRepository] and none of them ever
/// executed the branch the web build actually runs.
///
/// `ApiRepository(isWeb: true)` makes that branch run here, on a VM where
/// `kIsWeb` is false. Two consequences the tests lean on:
///
///  * the popup must come from `FirebaseAuth` for this to be testable at all,
///    which is why it lives on the Firebase side rather than on `google_sign_in`;
///    and
///  * if this branch ever reaches for `google_sign_in` again, that plugin is not
///    registered on the test VM, so the call fails loudly instead of passing
///    quietly.
class _PopupRecordingAuth extends MockFirebaseAuth {
  _PopupRecordingAuth({super.mockUser});

  /// Every provider handed to `signInWithPopup`, in call order.
  final List<AuthProvider> popupRequests = <AuthProvider>[];

  /// Count of `signInWithCredential` calls — the *native* exchange. A web
  /// sign-in must not make any: the popup already completed it.
  int credentialExchanges = 0;

  /// When non-null, the next popup fails with this instead of signing in.
  Object? popupError;

  @override
  Future<UserCredential> signInWithPopup(AuthProvider provider) {
    popupRequests.add(provider);
    final Object? failure = popupError;
    if (failure != null) return Future<UserCredential>.error(failure);
    return super.signInWithPopup(provider);
  }

  @override
  Future<UserCredential> signInWithCredential(AuthCredential? credential) {
    credentialExchanges++;
    return super.signInWithCredential(credential);
  }
}

void main() {
  late _PopupRecordingAuth auth;
  late ApiRepository repo;
  late MockUser googleUser;

  setUp(() {
    googleUser = MockUser(
      uid: 'web-uid-1',
      email: 'someone@example.com',
      displayName: 'Someone',
    );
    auth = _PopupRecordingAuth(mockUser: googleUser);
    repo = ApiRepository(isWeb: true);
  });

  test('web sign-in uses the Firebase popup with a Google provider', () async {
    final User signedIn = await repo.handleGoogleSignIn(auth);

    expect(auth.popupRequests, hasLength(1), reason: 'one tap is one popup');
    expect(auth.popupRequests.single.providerId, 'google.com',
        reason: 'the popup must be a Google popup, not some other provider');
    expect(signedIn.uid, 'web-uid-1');
  });

  test('web sign-in completes without the google_sign_in plugin', () async {
    // `google_sign_in` is not registered on the test VM. Had this path still
    // called GoogleSignIn.instance.initialize() / authenticate() — the calls
    // that broke the released build — it could not have got here. Reaching a
    // signed-in user at all is the assertion.
    final User signedIn = await repo.handleGoogleSignIn(auth);

    expect(signedIn, isA<User>());
    expect(auth.currentUser?.uid, 'web-uid-1',
        reason: 'the popup leaves this client signed in, which is what the '
            'token fetch reads back');
  });

  test('the web popup is not followed by a second credential exchange',
      () async {
    await repo.handleGoogleSignIn(auth);

    // The interface returns a User rather than a credential precisely so the
    // bloc cannot (and does not) run a second sign-in to turn a popup into a
    // session. On the web a second exchange would mean a second popup.
    expect(auth.credentialExchanges, 0);
  });

  test('a blocked popup propagates the Firebase error', () async {
    auth.popupError = FirebaseAuthException(code: 'popup_blocked_by_browser');

    // The repository must not swallow this: ApiBloc turns it into the reason
    // shown on the sign-in screen (see the failure contract in
    // test/bloc/api_bloc_test.dart).
    await expectLater(
      repo.handleGoogleSignIn(auth),
      throwsA(isA<FirebaseAuthException>()
          .having((e) => e.code, 'code', 'popup_blocked_by_browser')),
    );
    expect(auth.currentUser, isNull, reason: 'nothing was signed in');
  });

  test('a popup that completes with no user is an error, not a null', () async {
    // Mirrors the native path's guard: a completion with no user is a failure
    // the caller has to see, never a null to crash on later.
    final auth2 = _PopupRecordingAuth();
    final repo2 = ApiRepository(isWeb: true);
    auth2.popupError =
        StateError('Google sign-in popup completed with no user');

    await expectLater(
      repo2.handleGoogleSignIn(auth2),
      throwsA(isA<StateError>()),
    );
  });

  test('the default constructor follows the real platform (native on the VM)',
      () async {
    // No isWeb: injected -> kIsWeb is false under `flutter test`, so the native
    // transport is selected and google_sign_in is reached. That plugin is absent
    // here, so this throws for want of a plugin — and, crucially, not via
    // signInWithPopup, which is the web-only route the default must not take.
    final defaultRepo = ApiRepository();

    await expectLater(defaultRepo.handleGoogleSignIn(auth), throwsA(anything));
    expect(auth.popupRequests, isEmpty,
        reason: 'off the web the popup is not used');
  });
}
