import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/blocs/api/api_bloc.dart';
import 'package:realoptions/blocs/api/api_state.dart';
import 'package:realoptions/blocs/api/api_events.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:realoptions/repositories/api_repository.dart';
import '../mocks/api_repository_mock.dart';
import 'package:bloc_test/bloc_test.dart';

void main() {
  MockFirebaseAuth auth;
  MockApiRepository apiRepository;
  ApiBloc bloc;
  setUp(() {
    auth = MockFirebaseAuth(signedIn: true);
    apiRepository = MockApiRepository();
    bloc = ApiBloc(firebaseAuth: auth, apiRepository: apiRepository);
  });
  tearDown(() {
    auth = null;
    bloc.close();
  });
  test('correct initial state', () async {
    expect(bloc.state, ApiIsFetching());
  });
  blocTest(
    'emits [fetching, token] when RequestApiKey is added',
    build: () => bloc,
    act: (bloc) => bloc.add(ApiEvents.RequestApiKey),
    expect: [ApiIsFetching(), ApiToken(token: "fake_token")],
  );

  // The sign-in paths previously had no coverage at all, and the shared fake made
  // Facebook indistinguishable from Google. This group records which repository
  // method the bloc actually routes each event to, and hands back the user it was
  // given, so the assertions do not depend on firebase mock internals.
  group('sign-in routing', () {
    MockFirebaseAuth auth;
    _RecordingAuthRepository repo;
    ApiBloc bloc;

    setUp(() {
      auth = MockFirebaseAuth(signedIn: true);
      repo = _RecordingAuthRepository(auth.currentUser);
      bloc = ApiBloc(firebaseAuth: auth, apiRepository: repo);
    });
    tearDown(() {
      bloc.close();
    });

    blocTest(
      'GoogleSignIn routes to handleGoogleSignIn and reaches a token',
      build: () => bloc,
      act: (bloc) => bloc.handleGoogleSignIn(),
      expect: [ApiIsFetching(), ApiIsFetching(), ApiToken(token: "fake_token")],
      verify: (bloc) {
        expect(repo.calls, ['google', 'convert:google.com', 'token']);
      },
    );

    blocTest(
      'FacebookSignIn routes to handleFacebookSignIn, not the Google path',
      build: () => bloc,
      act: (bloc) => bloc.handleFacebookSignIn(),
      expect: [ApiIsFetching(), ApiIsFetching(), ApiToken(token: "fake_token")],
      verify: (bloc) {
        expect(repo.calls, ['facebook', 'convert:facebook.com', 'token']);
        expect(repo.calls, isNot(contains('google')));
      },
    );
  });
}

/// Records which [AuthRepository] methods the bloc calls, and with which
/// credential provider, so routing can be asserted without a real (or mocked)
/// identity-provider round-trip.
class _RecordingAuthRepository implements AuthRepository {
  _RecordingAuthRepository(this.user);

  final User user;
  final List<String> calls = <String>[];

  @override
  Future<AuthCredential> handleGoogleSignIn(FirebaseAuth auth) async {
    calls.add('google');
    return GoogleAuthProvider.credential(
        accessToken: 'fake_google_access_token',
        idToken: 'fake_google_id_token');
  }

  @override
  Future<AuthCredential> handleFacebookSignIn(FirebaseAuth auth) async {
    calls.add('facebook');
    return FacebookAuthProvider.credential('fake_facebook_access_token');
  }

  @override
  Future<User> convertCredentialToUser(
      FirebaseAuth auth, AuthCredential credential) async {
    calls.add('convert:${credential.providerId}');
    // Return the already-signed-in mock user rather than calling back into the
    // auth plugin, so the test asserts routing only.
    return user;
  }

  @override
  Future<String> getToken(User user) async {
    calls.add('token');
    return "fake_token";
  }
}
