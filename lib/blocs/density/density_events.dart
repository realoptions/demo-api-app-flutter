import 'package:flutter/material.dart';

abstract class DensityEvents {}

class RequestDensity extends DensityEvents {
  final Map<String, dynamic> body;
  RequestDensity({@required this.body});
}
