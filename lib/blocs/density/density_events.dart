import 'package:flutter/material.dart';
import 'package:realoptions/models/forms.dart';

abstract class DensityEvents {}

class RequestDensity extends DensityEvents {
  final Map<String, SubmitItems> body;
  RequestDensity({@required this.body});
}
