import 'package:equatable/equatable.dart';
import 'package:realoptions/models/forms.dart';

abstract class ConstraintsState extends Equatable {
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
