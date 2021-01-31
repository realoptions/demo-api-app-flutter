import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

abstract class ApiState extends Equatable {}

class ApiToken extends ApiState {
  final String token;
  ApiToken({@required this.token});
  @override
  List<Object> get props => [token];
}

class ApiIsFetching extends ApiState {
  @override
  List<Object> get props => [];
}

class ApiNoData extends ApiState {
  @override
  List<Object> get props => [];
}

class ApiError extends ApiState {
  final Error apiError;
  ApiError({@required this.apiError});
  @override
  List<Object> get props => [apiError];
}
