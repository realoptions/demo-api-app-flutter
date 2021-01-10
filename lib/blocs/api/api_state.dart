import 'package:flutter/material.dart';
abstract class ApiState {}

class ApiToken extends ApiState{
  final String token;
  ApiToken({@required this.token});
}

class ApiIsFetching extends ApiState{

}

class ApiNoData extends ApiState{}

//class ApiError extends ApiState{}