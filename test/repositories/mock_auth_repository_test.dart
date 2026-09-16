import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

import '../mocks/api_repository_mock.dart';

/// Pins what the shared auth fake actually completes.
///
/// The fake once handed back a *Google* credential on the Facebook path as well
/// (copy-pasted, with a comment admitting it only existed to satisfy the
/// abstract class), which made every "signed in with Facebook" assertion in the
/// suite meaningless. What still matters now that the seam returns a `User`
/// rather than a credential: the fake must really run the exchange through the
/// injected `FirebaseAuth`, and really leave it signed in — so a test that
/// depends on a session is not depending on a stub's good intentions.
///
/// The transport itself is pinned elsewhere: `ApiRepository`'s native path by
/// its own shape, and the web popup path against the real class in
/// `api_repository_web_test.dart`.
void main() {
  late MockFirebaseAuth auth;
  late MockApiRepository repo;

  setUp(() {
    auth = MockFirebaseAuth();
    repo = MockApiRepository();
  });

  test('fake Google sign-in returns a User and leaves Firebase signed in',
      () async {
    expect(auth.currentUser, isNull, reason: 'starts signed out');

    final User user = await repo.handleGoogleSignIn(auth);

    expect(user, isA<User>());
    expect(auth.currentUser?.uid, user.uid,
        reason:
            'the credential exchange went through the injected FirebaseAuth');
  });

  test('fake getToken returns a non-empty token for that user', () async {
    final User user = await repo.handleGoogleSignIn(auth);

    expect(await repo.getToken(user), isNotEmpty);
  });
}
