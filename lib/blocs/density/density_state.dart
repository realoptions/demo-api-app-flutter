import 'package:realoptions/models/response.dart';
import 'package:equatable/equatable.dart';

abstract class DensityState extends Equatable {}

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
