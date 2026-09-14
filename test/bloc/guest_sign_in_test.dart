import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/blocs/api/api_bloc.dart';
import 'package:realoptions/blocs/api/api_events.dart';
import 'package:realoptions/blocs/api/api_state.dart';
import 'package:realoptions/demo_config.dart';
import 'package:realoptions/repositories/api_repository.dart';

/// Records the repository methods the bloc reaches for, so the assertions are
/// about routing rather than about firebase mock internals.
///
/// The social methods are deliberately present-but-boobytrapped: a guest path
/// that quietly fell through to Google would be caught by the recorded call list.
class _RecordingRepository implements AuthRepository {
  _RecordingRepository(this.user, {this.guestError});

  final User? user;
  final Object? guestError;
  final List<String> calls = <String>[];

  @override
  Future<AuthCredential> handleGoogleSignIn(FirebaseAuth auth) async {
    calls.add('google');
    throw UnimplementedError('guest path must not use Google');
  }

  @override
  Future<AuthCredential> handleFacebookSignIn(FirebaseAuth auth) async {
    calls.add('facebook');
    throw UnimplementedError('guest path must not use Facebook');
  }

  @override
  Future<User> signInAsGuest(FirebaseAuth auth) async {
    calls.add('guest');
    if (guestError != null) {
      throw guestError!;
    }
    return user!;
  }

  @override
  Future<User> convertCredentialToUser(
      FirebaseAuth auth, AuthCredential credential) async {
    calls.add('convert:${credential.providerId}');
    return user!;
  }

  @override
  Future<String> getToken(User user) async {
    calls.add('token');
    return 'guest_token';
  }
}

void main() {
  group('DemoConfig.guestLoginEnabled rule', () {
    test('defaults to on for the web build (the demo)', () {
      expect(DemoConfig.resolveGuestLogin(isWeb: true, override: ''), isTrue);
    });

    test('defaults to off for every other build', () {
      expect(DemoConfig.resolveGuestLogin(isWeb: false, override: ''), isFalse);
    });

    test('the build-time override wins in both directions', () {
      expect(
        DemoConfig.resolveGuestLogin(isWeb: false, override: 'true'),
        isTrue,
      );
      expect(
        DemoConfig.resolveGuestLogin(isWeb: true, override: 'false'),
        isFalse,
      );
    });

    test('only the literal "true" enables it, so a typo cannot open the door',
        () {
      expect(
        DemoConfig.resolveGuestLogin(isWeb: false, override: 'yes'),
        isFalse,
      );
      expect(
        DemoConfig.resolveGuestLogin(isWeb: false, override: 'TRUE'),
        isFalse,
      );
    });
  });

  group('ApiRepository.signInAsGuest', () {
    test('signs an anonymous user in from a signed-out client', () async {
      final MockFirebaseAuth auth = MockFirebaseAuth();
      final User user = await ApiRepository().signInAsGuest(auth);

      expect(user.isAnonymous, isTrue);
      expect(auth.currentUser?.isAnonymous, isTrue);
    });

    test('reuses an existing anonymous session instead of minting a new uid',
        () async {
      final MockFirebaseAuth auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(isAnonymous: true),
      );
      final ApiRepository repo = ApiRepository();

      final User first = await repo.signInAsGuest(auth);
      final User second = await repo.signInAsGuest(auth);

      // Each signInAnonymously() on a signed-out client creates a *new* Firebase
      // user, so re-entering the demo would otherwise pile up throwaway accounts.
      expect(second.uid, first.uid);
    });

    test('does not downgrade a signed-in social user to anonymous', () async {
      final MockFirebaseAuth auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'social-uid', isAnonymous: false),
      );

      final User user = await ApiRepository().signInAsGuest(auth);

      expect(user.uid, 'social-uid');
      expect(user.isAnonymous, isFalse);
    });
  });

  group('ApiBloc guest sign-in', () {
    late MockFirebaseAuth auth;
    late _RecordingRepository repo;

    setUp(() {
      auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'guest-uid', isAnonymous: true),
      );
    });

    blocTest<ApiBloc, ApiState>(
      'reaches a token without touching a social provider',
      build: () {
        repo = _RecordingRepository(auth.currentUser);
        return ApiBloc(firebaseAuth: auth, apiRepository: repo);
      },
      act: (ApiBloc bloc) => bloc.handleGuestSignIn(),
      // bloc delivers the first emit even when it equals the initial state and
      // then drops consecutive duplicates (bloc_base.dart: `state == _state &&
      // _emitted`), so the two ApiIsFetching emits in the handler collapse into
      // one.
      expect: () => const <ApiState>[
        ApiIsFetching(),
        ApiToken(token: 'guest_token'),
      ],
      verify: (ApiBloc bloc) {
        expect(repo.calls, <String>['guest', 'token']);
        expect(repo.calls, isNot(contains('google')));
        expect(repo.calls, isNot(contains('facebook')));
        // Anonymous auth has no credential to exchange, so the social paths'
        // convert step must not run.
        expect(repo.calls, isNot(contains(startsWith('convert:'))));
      },
    );

    blocTest<ApiBloc, ApiState>(
      'a rejected anonymous sign-in returns to the sign-in screen',
      build: () {
        repo = _RecordingRepository(
          null,
          guestError: FirebaseAuthException(
            code: 'operation-not-allowed',
            message: 'Anonymous auth is not enabled on this project.',
          ),
        );
        return ApiBloc(firebaseAuth: auth, apiRepository: repo);
      },
      act: (ApiBloc bloc) => bloc.handleGuestSignIn(),
      // The point of this test: the state must not settle on ApiIsFetching, which
      // renders as a spinner with no way back. ApiNoData is the screen that still
      // offers the sign-in buttons.
      expect: () => const <ApiState>[ApiIsFetching(), ApiNoData()],
      verify: (ApiBloc bloc) {
        expect(bloc.state, isA<ApiNoData>());
        expect(bloc.state, isNot(isA<ApiIsFetching>()));
      },
    );

    blocTest<ApiBloc, ApiState>(
      'the guest event is routed separately from the social events',
      build: () {
        repo = _RecordingRepository(auth.currentUser);
        return ApiBloc(firebaseAuth: auth, apiRepository: repo);
      },
      act: (ApiBloc bloc) => bloc.add(ApiEvents.GuestSignIn),
      verify: (ApiBloc bloc) {
        expect(repo.calls.first, 'guest');
      },
    );
  });
}
