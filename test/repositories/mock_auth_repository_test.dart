import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

import '../mocks/api_repository_mock.dart';

/// Guards the shape of the credentials the shared auth fake produces.
///
/// The Facebook path used to return a *Google* credential (copy-pasted with a
/// comment saying it only existed to satisfy the abstract class), which made any
/// "signed in with Facebook" assertion meaningless. These tests pin each path to
/// its own provider id so a copy-paste regression fails loudly.
void main() {
  MockApiRepository repo;
  FirebaseAuth auth;

  setUp(() {
    repo = MockApiRepository();
    auth = MockFirebaseAuth();
  });

  tearDown(() {
    repo = null;
    auth = null;
  });

  test('fake Facebook sign-in returns a facebook.com credential', () async {
    final credential = await repo.handleFacebookSignIn(auth);
    expect(credential.providerId, 'facebook.com');
  });

  test('fake Google sign-in returns a google.com credential', () async {
    final credential = await repo.handleGoogleSignIn(auth);
    expect(credential.providerId, 'google.com');
  });

  test('the two paths are not the same credential', () async {
    final facebook = await repo.handleFacebookSignIn(auth);
    final google = await repo.handleGoogleSignIn(auth);
    expect(facebook.providerId, isNot(google.providerId));
  });
}
