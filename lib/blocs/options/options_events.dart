import 'package:flutter/material.dart';

abstract class OptionsEvents {}

class RequestOptions extends OptionsEvents {
  final Map<String, dynamic> body;
  RequestOptions({@required this.body});
}
