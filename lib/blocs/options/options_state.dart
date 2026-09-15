import 'package:realoptions/models/response.dart';
import 'package:equatable/equatable.dart';

/// Every state the options bloc can be in.
///
/// Sealed on purpose. A widget that switches over this is checked for
/// exhaustiveness, so adding a state here is a compile error at every site
/// that has not said what to do with it - instead of falling through, unseen,
/// onto the spinner those sites used to end with.
sealed class OptionsState extends Equatable {
  /// Whether an option-price request is in flight.
  ///
  /// An exhaustive switch rather than `this is IsOptionsFetching`, for the same
  /// reason the class is sealed: a new state has to declare whether it counts
  /// as busy, and the compiler is the one asking.
  bool get isFetching => switch (this) {
        IsOptionsFetching() => true,
        OptionsNoData() || OptionsError() || OptionsData() => false,
      };
}

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
