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

class VaRResult {
  final num valueAtRisk;
  final num expectedShortfall;
  VaRResult({@required this.valueAtRisk, @required this.expectedShortfall});
  factory VaRResult.fromJson(Map<String, dynamic> parsedJson) {
    return VaRResult(
        valueAtRisk: parsedJson['value_at_risk'],
        expectedShortfall: parsedJson['expected_shortfall']);
  }
}

class DensityAndVaR {
  final List<ModelResult> density;
  final VaRResult riskMetrics;
  DensityAndVaR({@required this.density, @required this.riskMetrics});
}
