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
  late MockFirebaseAuth auth;
  late MockApiRepository apiRepository;
  late ApiBloc bloc;
  setUp(() {
    auth = MockFirebaseAuth(signedIn: true);
    apiRepository = MockApiRepository();
    bloc = ApiBloc(firebaseAuth: auth, apiRepository: apiRepository);
  });
  tearDown(() {
    bloc.close();
  });
  test('correct initial state', () async {
    expect(bloc.state, ApiIsFetching());
  });
  blocTest(
    'emits [fetching, token] when RequestApiKey is added',
    build: () => bloc,
    act: (bloc) => bloc.add(ApiEvents.RequestApiKey),
    // The token is whatever the Firebase fake mints (a real-shaped JWT), not a
    // fixed string, so the assertion is on the state type plus a non-empty
    // token rather than on a literal that would drift with the fake.
    expect: () => [ApiIsFetching(), isA<ApiToken>()],
    verify: (bloc) {
      expect((bloc.state as ApiToken).token, isNotEmpty);
    },
  );

  // bloc 9 drops a state that equals the current one once something has been
  // emitted (`if (state == _state && _emitted) return` in BlocBase.emit). Both
  // sign-in paths emit ApiIsFetching for the sign-in and again for the token
  // fetch, so the second one is coalesced and the recorded sequence is two
  // states, not three.
  //
  // The sign-in paths previously had no coverage at all. This group records which
  // repository method the bloc actually routes each event to, and hands back the
  // user it was given, so the assertions do not depend on firebase mock
  // internals.
  group('sign-in routing', () {
    late MockFirebaseAuth auth;
    late _RecordingAuthRepository repo;
    late ApiBloc bloc;

    setUp(() {
      auth = MockFirebaseAuth(signedIn: true);
      repo = _RecordingAuthRepository(auth.currentUser!);
      bloc = ApiBloc(firebaseAuth: auth, apiRepository: repo);
    });
    tearDown(() {
      bloc.close();
    });

    blocTest(
      'GoogleSignIn routes to handleGoogleSignIn and reaches a token',
      build: () => bloc,
      act: (bloc) => bloc.handleGoogleSignIn(),
      expect: () => [ApiIsFetching(), ApiToken(token: "fake_token")],
      verify: (bloc) {
        expect(repo.calls, ['google', 'convert:google.com', 'token']);
      },
    );

  });

  // A sign-in that does not complete used to be logged and dropped. In a
  // released web build that is the same as saying nothing at all: the Dart
  // developer-event channel the log goes to has no listener there, so the
  // screen came back looking exactly as it did before the button was pressed.
  // These pin the contract that replaced it — back to ApiNoData with a reason
  // attached, and the token fetch never attempted.
  group('failed Google sign-in surfaces the Firebase error', () {
    late _FailingAuthRepository repo;
    late ApiBloc bloc;

    setUp(() {
      repo = _FailingAuthRepository(
        auth.currentUser!,
        FirebaseAuthException(code: 'network-request-failed'),
      );
      bloc = ApiBloc(firebaseAuth: auth, apiRepository: repo);
    });
    tearDown(() {
      bloc.close();
    });

    blocTest(
      'emits ApiNoData carrying the Firebase error code',
      build: () => bloc,
      act: (bloc) => bloc.handleGoogleSignIn(),
      expect: () => [
        ApiIsFetching(),
        predicate<ApiState>((state) =>
            state is ApiNoData &&
            (state.message ?? '').contains('network-request-failed')),
      ],
      verify: (bloc) {
        // Failed before a credential ever existed, so no token was fetched.
        expect(repo.calls, ['google']);
      },
    );
  });

  group('failed Google sign-in surfaces a non-Firebase error', () {
    late _FailingAuthRepository repo;
    late ApiBloc bloc;

    setUp(() {
      repo = _FailingAuthRepository(
        auth.currentUser!,
        StateError('Google sign-in returned no ID token'),
      );
      bloc = ApiBloc(firebaseAuth: auth, apiRepository: repo);
    });
    tearDown(() {
      bloc.close();
    });

    blocTest(
      'emits ApiNoData carrying the thrown error text',
      build: () => bloc,
      act: (bloc) => bloc.handleGoogleSignIn(),
      expect: () => [
        ApiIsFetching(),
        predicate<ApiState>((state) =>
            state is ApiNoData &&
            (state.message ?? '').contains('returned no ID token')),
      ],
      verify: (bloc) {
        expect(repo.calls, ['google']);
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

/// [AuthRepository] whose Google sign-in throws [error] instead of returning a
/// credential, so the bloc's failure contract can be asserted without standing
/// up a failing identity provider.
class _FailingAuthRepository implements AuthRepository {
  _FailingAuthRepository(this.user, this.error);

  final User user;
  final Object error;
  final List<String> calls = <String>[];

  @override
  Future<AuthCredential> handleGoogleSignIn(FirebaseAuth auth) async {
    calls.add('google');
    throw error;
  }

  @override
  Future<User> convertCredentialToUser(
      FirebaseAuth auth, AuthCredential credential) async {
    calls.add('convert:${credential.providerId}');
    return user;
  }

  @override
  Future<String> getToken(User user) async {
    calls.add('token');
    return "fake_token";
  }
}
