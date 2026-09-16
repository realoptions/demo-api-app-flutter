import 'package:equatable/equatable.dart';

/// Every state the api bloc can be in.
///
/// Sealed so the startup page that switches over it is checked for
/// exhaustiveness: a new state has to be handled, not absorbed by a fallback
/// spinner.
sealed class ApiState extends Equatable {
  const ApiState();
}

class ApiToken extends ApiState {
  final String token;
  const ApiToken({required this.token});
  @override
  List<Object> get props => [token];
}

class ApiIsFetching extends ApiState {
  const ApiIsFetching();
  @override
  List<Object> get props => [];
}

class ApiNoData extends ApiState {
  const ApiNoData({this.message});

  /// Why there is no data — e.g. the reason a sign-in attempt did not complete.
  ///
  /// Carried on the state rather than only written to the log because
  /// `dart:developer log()` publishes to the Dart developer-event channel, and
  /// a released web build has no listener attached to it. A sign-in that failed
  /// there is invisible: it looked exactly like a button that was never pressed.
  /// The screen that offers the button again needs the reason in its own data.
  final String? message;

  @override
  List<Object?> get props => [message];
}

class ApiError extends ApiState {
  /// Widened from `Error` to `Object`: the bloc reports whatever the repository
  /// or auth layer threw, and a failed network/auth call normally surfaces as an
  /// `Exception`, not an `Error`. Narrowing it back would mean casting the
  /// caught object, which is exactly the kind of unchecked assumption that
  /// turns a reportable failure into a crash.
  final Object apiError;
  const ApiError({required this.apiError});
  @override
  List<Object> get props => [apiError];
}
