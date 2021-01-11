import 'package:flutter/material.dart';
import 'package:realoptions/models/response.dart';

abstract class OptionsState {}

class NoData extends OptionsState {}

class IsOptionsFetching extends OptionsState {}

class OptionsError extends OptionsState {
  final Error optionsError;
  OptionsError({@required this.optionsError});
}

class OptionsData extends OptionsState {
  final Map<String, List<ModelResult>> options;
  OptionsData({@required this.options});
}
