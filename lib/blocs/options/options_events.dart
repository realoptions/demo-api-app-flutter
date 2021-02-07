import 'package:flutter/material.dart';

abstract class OptionsEvents {}

class RequestOptions extends OptionsEvents {
  final Map<String, dynamic> body;
  final String model;
  RequestOptions({@required this.body, @required this.model});
}
