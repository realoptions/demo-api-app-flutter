import 'package:flutter/material.dart';
import 'package:realoptions/models/response.dart';
import 'package:equatable/equatable.dart';

abstract class OptionsState extends Equatable {}

class NoData extends OptionsState {
  @override
  List<Object> get props => [];
}

class IsOptionsFetching extends OptionsState {
  @override
  List<Object> get props => [];
}

class OptionsError extends OptionsState {
  final String optionsError;
  OptionsError({@required this.optionsError});
  @override
  List<Object> get props => [optionsError];
}

class OptionsData extends OptionsState {
  final Map<String, List<ModelResult>> options;
  OptionsData({@required this.options});
  @override
  List<Object> get props => [options];
}
