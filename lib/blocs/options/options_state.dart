import 'package:realoptions/models/response.dart';
import 'package:equatable/equatable.dart';

abstract class OptionsState extends Equatable {}

/// No option prices have been fetched yet.
///
/// Prefixed with `Options` the way `ApiNoData` is prefixed with `Api`: this
/// file and `density_state.dart` used to both declare a bare `NoData`, so a
/// `is NoData` check copied between the two pages compiled against the wrong
/// hierarchy.
class OptionsNoData extends OptionsState {
  @override
  List<Object> get props => [];
}

class IsOptionsFetching extends OptionsState {
  @override
  List<Object> get props => [];
}

class OptionsError extends OptionsState {
  final String optionsError;
  OptionsError({required this.optionsError});
  @override
  List<Object> get props => [optionsError];
}

class OptionsData extends OptionsState {
  final OptionPrices options;
  OptionsData({required this.options});
  @override
  List<Object> get props => [options];
}
