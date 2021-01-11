import 'package:flutter/material.dart';
import 'package:realoptions/models/forms.dart';

abstract class OptionsEvents {}

class RequestOptions extends OptionsEvents {
  final Map<String, SubmitItems> body;
  RequestOptions({@required this.body});
}
