import 'package:realoptions/models/response.dart';
import 'package:equatable/equatable.dart';

/// Every state the density bloc can be in.
///
/// Sealed on purpose. A widget that switches over this is checked for
/// exhaustiveness, so adding a state here is a compile error at every site
/// that has not said what to do with it - instead of falling through, unseen,
/// onto the spinner those sites used to end with.
sealed class DensityState extends Equatable {
  /// Whether a density request is in flight.
  ///
  /// An exhaustive switch rather than `this is IsDensityFetching`, for the same
  /// reason the class is sealed: a new state has to declare whether it counts
  /// as busy, and the compiler is the one asking.
  bool get isFetching => switch (this) {
        IsDensityFetching() => true,
        DensityNoData() || DensityError() || DensityData() => false,
      };
}

/// No density has been fetched yet.
///
/// Prefixed with `Density` the way `ApiNoData` is prefixed with `Api`: this
/// file and `options_state.dart` used to both declare a bare `NoData`, so an
/// `is NoData` check copied between the two pages compiled against the wrong
/// hierarchy.
class DensityNoData extends DensityState {
  @override
  List<Object> get props => [];
}

class IsDensityFetching extends DensityState {
  @override
  List<Object> get props => [];
}

class DensityError extends DensityState {
  final String densityError;
  DensityError({required this.densityError});
  @override
  List<Object> get props => [densityError];
}

class DensityData extends DensityState {
  final DensityAndVaR density;
  DensityData({required this.density});
  @override
  List<Object> get props => [density];
}
