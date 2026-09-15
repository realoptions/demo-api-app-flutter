import 'dart:async';
import 'dart:developer' as developer;

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../repositories/api_repository.dart';
import './api_events.dart';
import './api_state.dart';

final String apiKeyId = "apiKey";

/// Drives sign-in and the API-token fetch.
///
/// Migrated from `mapEventToState` (removed in bloc 7) to per-event handlers
/// registered with `on<E>`. [ApiEvents] is an enum rather than a class
/// hierarchy, and `on<E>` keys handlers on the event *type*, so every value
/// arrives through the single [ApiEvents] registration; [_onEvent] then
/// dispatches to one explicit handler method per value. The public surface
/// (`handleGoogleSignIn`, `handleFacebookSignIn`, `setNoData`, the event enum)
/// is unchanged, so `main.dart` and the pages need no changes.
class ApiBloc extends Bloc<ApiEvents, ApiState> {
  final FirebaseAuth firebaseAuth;
  final AuthRepository apiRepository;

  ApiBloc({required this.firebaseAuth, required this.apiRepository})
      : super(ApiIsFetching()) {
    on<ApiEvents>(_onEvent);
  }

  void handleGoogleSignIn() {
    add(ApiEvents.GoogleSignIn);
  }

  void handleFacebookSignIn() {
    add(ApiEvents.FacebookSignIn);
  }

  /// Guest entry point for the hosted demo (see `DemoConfig.guestLoginEnabled`).
  void handleGuestSignIn() {
    add(ApiEvents.GuestSignIn);
  }

  void setNoData() {
    add(ApiEvents.SignOut);
  }

  Future<void> _onEvent(ApiEvents event, Emitter<ApiState> emit) async {
    switch (event) {
      case ApiEvents.SignOut:
        await _onSignOut(emit);
        break;
      case ApiEvents.RequestApiKey:
        await _requestApiKey(emit);
        break;
      case ApiEvents.GoogleSignIn:
        await _onGoogleSignIn(emit);
        break;
      case ApiEvents.FacebookSignIn:
        await _onFacebookSignIn(emit);
        break;
      case ApiEvents.GuestSignIn:
        await _onGuestSignIn(emit);
        break;
    }
  }

  Future<void> _onSignOut(Emitter<ApiState> emit) async {
    emit(ApiNoData());
  }

  Future<void> _onGoogleSignIn(Emitter<ApiState> emit) {
    return _signInThenFetchToken(
      () => apiRepository.handleGoogleSignIn(firebaseAuth),
      emit,
    );
  }

  Future<void> _onFacebookSignIn(Emitter<ApiState> emit) {
    return _signInThenFetchToken(
      () => apiRepository.handleFacebookSignIn(firebaseAuth),
      emit,
    );
  }

  /// Guest sign-in for the hosted demo: anonymous Firebase auth, then the same
  /// API-token fetch the social paths run.
  ///
  /// Deliberately not routed through [_signInThenFetchToken] — that helper is
  /// built around an [AuthCredential] and the `convertCredentialToUser`
  /// exchange, and anonymous auth has neither: `signInAnonymously` yields the
  /// user directly.
  ///
  /// What it does share with the social paths is the failure contract. A sign-in
  /// that does not complete returns to [ApiNoData] — the screen that offers the
  /// buttons again — instead of leaving [ApiIsFetching] up. That matters more
  /// here than it does for a dismissed popup: the likeliest failure is the
  /// Firebase project not having the Anonymous provider enabled, and a visitor
  /// who hits that still needs the social buttons to be reachable.
  Future<void> _onGuestSignIn(Emitter<ApiState> emit) async {
    emit(ApiIsFetching());
    try {
      await apiRepository.signInAsGuest(firebaseAuth);
    } catch (error, stackTrace) {
      developer.log(
        'anonymous sign-in did not complete; returning to the sign-in screen',
        name: 'ApiBloc',
        error: error,
        stackTrace: stackTrace,
      );
      emit(ApiNoData());
      return;
    }
    await _requestApiKey(emit);
  }

  /// Sign in, then fetch the API token, emitting the same state sequence the old
  /// `mapEventToState` + re-entrant `add(ApiEvents.RequestApiKey)` produced.
  ///
  /// Two things worth calling out relative to the code it replaces:
  ///
  /// * **Spinner timing.** The old handler awaited the identity-provider round
  ///   trip *first* and only then `yield`ed [ApiIsFetching], so the UI had
  ///   nothing to show while the user was actually being signed in (and, on
  ///   web, while the popup round-trip was in flight). [ApiIsFetching] is now
  ///   emitted before the `await`, which is the point where a spinner is
  ///   wanted. The emitted sequence is unchanged.
  /// * **No re-entrancy.** The old handler ended with
  ///   `add(ApiEvents.RequestApiKey)` — a second event queued from inside a
  ///   running handler, so the token fetch depended on how the event queue
  ///   drained between handlers. The token request is now awaited directly by
  ///   the handler that owns the credential, via the same [_requestApiKey]
  ///   body the `RequestApiKey` handler runs. Behaviour is identical when the
  ///   queue is empty, but a token request can no longer be reordered with
  ///   respect to the sign-in that produced the credential it authorises.
  ///
  /// The sign-in failure path is handled here, which is *new*: previously the
  /// provider error (normally the user dismissing the login popup) escaped the
  /// generator to `Bloc.onError`, and the state was never touched, so the user
  /// stayed on [ApiNoData] — the screen that offers the sign-in buttons — and
  /// could retry. Moving the `ApiIsFetching` emit earlier means that escaped
  /// error would now leave the spinner up forever with no way back, so the error
  /// is caught and the state is put back to [ApiNoData]. The error itself is
  /// still logged, as `onError` used to log it; it is not surfaced as
  /// [ApiError] because `StartupPage` renders `ApiError` as terminal text with
  /// no retry affordance, which is the wrong thing to show for "user cancelled
  /// the login dialog".
  Future<void> _signInThenFetchToken(
    Future<AuthCredential> Function() signIn,
    Emitter<ApiState> emit,
  ) async {
    emit(ApiIsFetching());
    final AuthCredential credential;
    try {
      credential = await signIn();
    } catch (error, stackTrace) {
      developer.log(
        'sign-in did not complete; returning to the sign-in screen',
        name: 'ApiBloc',
        error: error,
        stackTrace: stackTrace,
      );
      emit(ApiNoData());
      return;
    }
    await apiRepository.convertCredentialToUser(firebaseAuth, credential);
    await _requestApiKey(emit);
  }

  /// Shared body for the [ApiEvents.RequestApiKey] handler, also called at the
  /// end of a sign-in (see [_signInThenFetchToken]).
  Future<void> _requestApiKey(Emitter<ApiState> emit) async {
    emit(ApiIsFetching());
    try {
      final User? user = firebaseAuth.currentUser;
      if (user != null) {
        final String token = await apiRepository.getToken(user);
        emit(ApiToken(token: token));
      } else {
        emit(ApiNoData());
      }
    } catch (err) {
      emit(ApiError(apiError: err));
    }
  }
}
