import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:realoptions/models/forms.dart';

abstract class ConstraintsState extends Equatable {}

class ConstraintsData extends ConstraintsState {
  final List<InputConstraint> constraints;
  ConstraintsData({@required this.constraints});
  @override
  List<Object> get props => [constraints];
}

class ConstraintsIsFetching extends ConstraintsState {
  @override
  List<Object> get props => [];
}

class ConstraintsError extends ConstraintsState {
  final String constraintsError;
  ConstraintsError({@required this.constraintsError});
  @override
  List<Object> get props => [constraintsError];
}
