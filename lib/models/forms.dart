import 'package:demo_api_app_flutter/components/CustomTextFields.dart';
import 'package:quiver/core.dart' show hash4;
import 'package:quiver/core.dart' show hash2;

enum InputType { Model, Market }
const String MARKET_NAME = "market";

class InputConstraint {
  final num lower;
  final num upper;
  final num defaultValue;
  final FieldType type;
  final String name;
  final InputType inputType;

  InputConstraint({
    this.lower,
    this.upper,
    this.type,
    this.name,
    this.defaultValue,
    this.inputType,
  });
  @override
  bool operator ==(other) {
    if (other is! InputConstraint) {
      return false;
    }
    if (lower != other.lower) {
      return false;
    }
    if (upper != other.upper) {
      return false;
    }
    if (type != other.types) {
      return false;
    }
    if (name != other.name) {
      return false;
    }
    if (inputType != other.inputType) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => hash4(lower, upper, name, defaultValue);
}

const NUM_STRIKES = 10;
const PERCENT_RANGE = 0.5;

List<InputConstraint> parseJson(
    Map<String, Map<String, dynamic>> response, String model) {
  List<InputConstraint> inputConstraints = [];
  response.forEach((key, value) {
    num lower = value['lower'];
    num upper = value['upper'];
    num defaultValue = (lower + upper) / 2.0;
    inputConstraints.add(InputConstraint(
        name: key,
        lower: value['lower'],
        upper: value['upper'],
        type: value['types'] == 'float' ? FieldType.Float : FieldType.Integer,
        defaultValue: defaultValue,
        inputType: model == MARKET_NAME ? InputType.Market : InputType.Model));
  });
  return inputConstraints;
}

class SubmitItems {
  final num value;
  final InputType inputType;
  const SubmitItems({this.value, this.inputType});
  @override
  bool operator ==(other) {
    if (other is! SubmitItems) {
      return false;
    }

    if (value != other.value) {
      return false;
    }
    if (inputType != other.inputType) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => hash2(value, inputType);
}

class SubmitBody {
  const SubmitBody({
    this.formBody,
  });
  final Map<String, SubmitItems> formBody;
  List<double> generateStrikes(int numStrikes, double percentRange) {
    double asset = formBody["asset"].value;
    List<double> strikes = [];
    double minStrike = (1.0 - percentRange) * asset;
    double maxStrike = (1.0 + percentRange) * asset;
    double dx = (maxStrike - minStrike) / (numStrikes - 1.0);
    for (int i = 0; i < numStrikes; ++i) {
      strikes.add(minStrike + i * dx);
    }
    return strikes;
  }

  Map convertSubmission() {
    Map<String, dynamic> convertedMap = {};
    formBody.forEach((key, value) {
      switch (value.inputType) {
        case InputType.Market:
          convertedMap[key] = value.value;
          break;
        case InputType.Model:
          if (!convertedMap.containsKey("cf_parameters")) {
            convertedMap["cf_parameters"] = {};
          }
          convertedMap["cf_parameters"][key] = value.value;
          break;
      }
    });
    convertedMap["strikes"] = generateStrikes(NUM_STRIKES, PERCENT_RANGE);
    return convertedMap;
  }
}
