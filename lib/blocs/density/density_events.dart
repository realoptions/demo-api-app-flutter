import 'package:flutter/material.dart';

abstract class DensityEvents {}

class RequestDensity extends DensityEvents {
  final Map<String, dynamic> body;
  String model;
  RequestDensity({@required this.body, @required this.model});
}
