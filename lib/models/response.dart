class ErrorMessage {
  String? message;
  ErrorMessage({this.message});
  factory ErrorMessage.fromJson(Map<String, dynamic> parsedJson) {
    return ErrorMessage(message: parsedJson['message']);
  }
}

class ModelResult {
  final num value;
  final num atPoint;
  final num? iv;
  ModelResult({
    required this.value,
    required this.atPoint,
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
  VaRResult({required this.valueAtRisk, required this.expectedShortfall});
  factory VaRResult.fromJson(Map<String, dynamic> parsedJson) {
    return VaRResult(
        valueAtRisk: parsedJson['value_at_risk'],
        expectedShortfall: parsedJson['expected_shortfall']);
  }
}

class DensityAndVaR {
  final List<ModelResult> density;
  final VaRResult riskMetrics;
  DensityAndVaR({required this.density, required this.riskMetrics});
}

/// One parameter's bounds, as returned by `parameters/parameter_ranges`.
///
/// The fields are nullable because the app tolerates a range that omits one:
/// `InputConstraint` carries nullable bounds too, and tightening this here
/// would turn a partial response into a crash where it used to be a blank.
/// What the type buys is that the wire names — including `types`, which does
/// not match the field it feeds — are read in exactly one place.
class ParameterRange {
  const ParameterRange({this.lower, this.upper, this.type, this.description});

  factory ParameterRange.fromJson(Map<String, dynamic> parsedJson) {
    return ParameterRange(
      lower: parsedJson['lower'],
      upper: parsedJson['upper'],
      type: parsedJson['types'],
      description: parsedJson['description'],
    );
  }

  final num? lower;
  final num? upper;
  final String? type;
  final String? description;
}

/// Call and put prices from one run of the calculator endpoints.
///
/// Replaces the `Map<String, List<ModelResult>>` this used to travel as, keyed
/// by the literals "call" and "put": a misspelling on either side of that map
/// was a `null` at the chart, not a compile error.
class OptionPrices {
  const OptionPrices({required this.calls, required this.puts});

  final List<ModelResult> calls;
  final List<ModelResult> puts;
}
