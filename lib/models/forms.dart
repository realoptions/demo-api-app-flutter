import 'package:demo_api_app_flutter/components/CustomTextFields.dart';

enum InputType { Model, Market }
const String MARKET_NAME = "market";

class InputConstraint {
  final num lower;
  final num upper;
  final num defaultValue;
  final FieldType types;
  final String name;
  final InputType inputType;

  InputConstraint({
    this.lower,
    this.upper,
    this.types,
    this.name,
    this.defaultValue,
    this.inputType,
  });
}

const NUM_STRIKES = 10;
const PERCENT_RANGE = 0.5;
List<double> generateStrikes(
    double asset, int numStrikes, double percentRange) {
  List<double> strikes = [];
  double minStrike = percentRange * asset;
  double maxStrike = (1.0 + percentRange) * asset;
  double dx = (maxStrike - minStrike) / (numStrikes - 1.0);
  for (int i = 0; i < numStrikes; ++i) {
    strikes.add(minStrike + i * dx);
  }
  return strikes;
}

class InputConstraints {
  List<InputConstraint> inputConstraints;
  InputConstraints({this.inputConstraints});

  factory InputConstraints.append(InputConstraints firstInputConstraints,
      InputConstraints secondInputConstraints) {
    return InputConstraints(inputConstraints: [
      ...firstInputConstraints.inputConstraints,
      ...secondInputConstraints.inputConstraints
    ]);
  }

  factory InputConstraints.fromJson(
      Map<String, Map<String, dynamic>> parsedJson, String model) {
    List<InputConstraint> inputConstraints = [];
    parsedJson.forEach((key, value) {
      num lower = value['lower'];
      num upper = value['upper'];
      num defaultValue = (lower + upper) / 2.0;
      inputConstraints.add(InputConstraint(
          name: key,
          lower: value['lower'],
          upper: value['upper'],
          types:
              value['types'] == 'float' ? FieldType.Float : FieldType.Integer,
          defaultValue: defaultValue,
          inputType:
              model == MARKET_NAME ? InputType.Market : InputType.Model));
    });
    return InputConstraints(inputConstraints: inputConstraints);
  }
}

class SubmitItems {
  final num value;
  final InputType inputType;
  const SubmitItems({this.value, this.inputType});
}
