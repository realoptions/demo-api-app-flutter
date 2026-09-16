import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;

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
/// dispatches to one explicit handler method per value.
///
/// Google is the only sign-in path here now. Facebook was dropped because the
/// hosted web build has no Facebook app id to log in with — not in Dart, not in
/// `web/index.html.template`, not in the deployed bundle — and anonymous/guest
/// access was dropped because the hosting project does not permit it. Both
/// removals are recorded in `lib/pages/intro.dart`.
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
  /// The sign-in failure path is handled here, which was *new* relative to the
  /// generator it replaces: previously the provider error (normally the user
  /// dismissing the login popup) escaped the generator to `Bloc.onError`, and
  /// the state was never touched, so the user stayed on [ApiNoData] — the
  /// screen that offers the sign-in buttons — and could retry. Moving the
  /// `ApiIsFetching` emit earlier means that escaped error would now leave the
  /// spinner up forever with no way back, so the error is caught and the state
  /// is put back to [ApiNoData].
  ///
  /// What the failure put on [ApiNoData] is the reason, not nothing. It used to
  /// be logged and dropped, and logging is not a visible channel in a released
  /// web build (see [ApiNoData.message]), so a sign-in that failed for a real
  /// reason — a rejected credential, a blocked popup, no network — was
  /// indistinguishable from a button nobody had pressed. It is not raised as
  /// [ApiError] because `StartupPage` renders `ApiError` as terminal text with
  /// no retry affordance, which is the wrong thing to show for "the login
  /// dialog did not work; try again".
  Future<void> _signInThenFetchToken(
    Future<AuthCredential> Function() signIn,
    Emitter<ApiState> emit,
  ) async {
    emit(ApiIsFetching());
    final AuthCredential credential;
    try {
      credential = await signIn();
    } catch (error, stackTrace) {
      // debugPrint rather than developer.log: the latter needs a listener on the
      // Dart developer-event channel, which a released web build does not have.
      debugPrint('sign-in did not complete: $error\n$stackTrace');
      emit(ApiNoData(message: _describeSignInFailure(error)));
      return;
    }
    await apiRepository.convertCredentialToUser(firebaseAuth, credential);
    await _requestApiKey(emit);
  }

  /// Turns a sign-in failure into one line for the sign-in screen.
  ///
  /// A [FirebaseAuthException] carries a machine-readable `code`
  /// (`network-request-failed`, `invalid-credential`, `popup_closed_by_user`,
  /// …) alongside the human `message`; the code is what identifies the fault
  /// when the message is generic, so both are included.
  static String _describeSignInFailure(Object error) {
    if (error is FirebaseAuthException) {
      final String detail = error.message ?? error.code;
      return 'Sign-in failed: $detail (${error.code})';
    }
    return 'Sign-in failed: $error';
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
