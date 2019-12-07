import 'package:flutter/foundation.dart';

class ErrorMessage {
  String message;
  ErrorMessage({this.message});
  factory ErrorMessage.fromJson(Map<String, dynamic> parsedJson) {
    return ErrorMessage(message: parsedJson['message']);
  }
}

class ModelResult {
  final num value;
  final num atPoint;
  final num iv;
  ModelResult({
    @required this.value,
    @required this.atPoint,
    this.iv,
  });
  factory ModelResult.fromJson(Map<String, dynamic> parsedJson) {
    return ModelResult(
      value: parsedJson['value'],
      atPoint: parsedJson['at_point'],
      iv: parsedJson['iv'],
    );
  }
}
