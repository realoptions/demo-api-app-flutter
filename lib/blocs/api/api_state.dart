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
  const ApiNoData();
  @override
  List<Object> get props => [];
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
