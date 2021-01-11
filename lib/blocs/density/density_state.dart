import 'package:flutter/material.dart';
import 'package:realoptions/models/response.dart';

abstract class DensityState {}

class NoData extends DensityState {}

class IsDensityFetching extends DensityState {}

class DensityError extends DensityState {
  final Error densityError;
  DensityError({@required this.densityError});
}

class DensityData extends DensityState {
  final DensityAndVaR density;
  DensityData({@required this.density});
}
