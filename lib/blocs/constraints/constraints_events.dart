import 'package:flutter/material.dart';
import 'package:realoptions/models/models.dart';

abstract class ConstraintsEvents {}

class RequestConstraints extends ConstraintsEvents {
  Model model;
  RequestConstraints({@required this.model});
}
