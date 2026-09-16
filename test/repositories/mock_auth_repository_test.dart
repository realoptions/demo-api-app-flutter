import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

import '../mocks/api_repository_mock.dart';

/// Pins the provider id of the credential the shared auth fake produces.
///
/// The fake once handed back a *Google* credential on the Facebook path as well
/// (copy-pasted, with a comment admitting it only existed to satisfy the
/// abstract class), which made every "signed in with Facebook" assertion in the
/// suite meaningless. Facebook is no longer part of the app; what survives is the
/// lesson in the one shape that still matters — the bloc's credential exchange is
/// keyed on the provider id, so the Google path has to really produce a
/// `google.com` credential rather than whatever a stub felt like returning.
void main() {
  late MockApiRepository repo;
  late FirebaseAuth auth;

  setUp(() {
    repo = MockApiRepository();
    auth = MockFirebaseAuth();
  });

  test('fake Google sign-in returns a google.com credential', () async {
    final credential = await repo.handleGoogleSignIn(auth);
    expect(credential.providerId, 'google.com');
  });
}
