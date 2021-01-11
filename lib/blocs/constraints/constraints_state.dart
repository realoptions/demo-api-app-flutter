import 'package:flutter/material.dart';
import 'package:realoptions/models/forms.dart';

abstract class ConstraintsState {}

class ConstraintsData extends ConstraintsState {
  final List<InputConstraint> constraints;
  ConstraintsData({@required this.constraints});
}

class ConstraintsIsFetching extends ConstraintsState {}

class ConstraintsError extends ConstraintsState {
  final Error constraintsError;
  ConstraintsError({@required this.constraintsError});
}
