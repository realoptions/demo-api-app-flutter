import 'package:equatable/equatable.dart';
import 'package:realoptions/models/forms.dart';

/// Every state the constraints bloc can be in.
///
/// Sealed so the shell that switches over it is checked for exhaustiveness:
/// a new state has to be handled, not absorbed by a fallback spinner.
sealed class ConstraintsState extends Equatable {
  const ConstraintsState();
}

class ConstraintsData extends ConstraintsState {
  final List<InputConstraint> constraints;
  const ConstraintsData({required this.constraints});
  @override
  List<Object> get props => [constraints];
}

class ConstraintsIsFetching extends ConstraintsState {
  const ConstraintsIsFetching();
  @override
  List<Object> get props => [];
}

class ConstraintsError extends ConstraintsState {
  final String constraintsError;
  const ConstraintsError({required this.constraintsError});
  @override
  List<Object> get props => [constraintsError];
}
