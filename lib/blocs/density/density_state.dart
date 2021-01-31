import 'package:flutter/material.dart';
import 'package:realoptions/models/response.dart';
import 'package:equatable/equatable.dart';

abstract class DensityState extends Equatable {}

class NoData extends DensityState {
  @override
  List<Object> get props => [];
}

class IsDensityFetching extends DensityState {
  @override
  List<Object> get props => [];
}

class DensityError extends DensityState {
  final String densityError;
  DensityError({@required this.densityError});
  @override
  List<Object> get props => [densityError];
}

class DensityData extends DensityState {
  final DensityAndVaR density;
  DensityData({@required this.density});
  @override
  List<Object> get props => [density];
}
