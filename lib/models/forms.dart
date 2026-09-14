import 'package:realoptions/components/CustomTextFields.dart';
import 'package:realoptions/models/api_request.dart';
import 'package:realoptions/models/models.dart';
import 'package:realoptions/models/response.dart';

enum InputType { Model, Market }

const String MARKET_NAME = "market";

/// One form field, as described by the API's `parameter_ranges`.
///
/// The identity of a field - what it is called, how it is typed, whether it is a
/// market or model parameter, and what it starts at - is always present in a
/// parsed constraint, so those are required and non-null: the form cannot render
/// a field without them. Only the bounds and the help text are genuinely
/// optional, because those arrive straight from JSON and may be absent.
class InputConstraint {
  final num? lower;
  final num? upper;
  final num defaultValue;
  final FieldType fieldType;
  final String name;
  final InputType inputType;
  final String? description;
  InputConstraint(
      {required this.name,
      required this.fieldType,
      required this.inputType,
      required this.defaultValue,
      this.lower,
      this.upper,
      this.description});
  @override
  bool operator ==(other) {
    if (other is! InputConstraint) {
      return false;
    }
    if (name != other.name) {
      return false;
    }
    return true;
  }

  @override
  // Hashed on `name` alone because that is all `operator ==` above compares.
  // The old hash4(lower, upper, name, defaultValue) hashed three fields that
  // equality ignores, so two constraints sharing a name but differing on a
  // bound compared equal while hashing differently - the contract that equal
  // objects must hash equal was broken. Note the reverse question is also
  // open: identity by name alone may well be too coarse for a type that
  // carries bounds, but that is a change to == and to how callers dedup,
  // not something to slip in under a dependency swap.
  int get hashCode => name.hashCode;
}

const NUM_STRIKES = 10;
const PERCENT_RANGE = 0.5;

/// Turns the decoded `parameter_ranges` response into the constraints the form
/// renders.
///
/// The response arrives as a [ParameterRange] per parameter rather than as a
/// map of dynamic, so a renamed field on the wire shows up as a null bound at
/// parse time instead of as a key lookup that quietly misses somewhere down
/// the line.
List<InputConstraint> parseJson(Map<String, ParameterRange> ranges,
    Map<String, num> defaultValues, String model) {
  return defaultValues.entries.map((entry) {
    // A missing parameter block is a broken API response, so it is a hard null
    // check rather than a silent `?? {}`: the alternative is a constraint with
    // no bounds reaching the form.
    final ParameterRange range = ranges[entry.key]!;
    return InputConstraint(
        name: entry.key,
        lower: range.lower,
        upper: range.upper,
        fieldType: range.type == 'float' ? FieldType.Float : FieldType.Integer,
        defaultValue: entry.value,
        inputType: model == MARKET_NAME ? InputType.Market : InputType.Model,
        description: range.description);
  }).toList();
}

class SubmitItems {
  final num value;
  final InputType inputType;
  const SubmitItems({required this.value, required this.inputType});
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
  int get hashCode => Object.hash(value, inputType);
}

/// Evenly spaced strikes centred on [asset].
///
/// Takes the asset as an argument rather than digging `formBody["asset"]` out of
/// a closure over the form: the ladder depends on one number, and naming it
/// makes the dependency visible and the function testable on its own.
List<double> generateStrikes({
  required num asset,
  required int numStrikes,
  required double percentRange,
}) {
  final double base = asset.toDouble();
  final double minStrike = (1.0 - percentRange) * base;
  final double maxStrike = (1.0 + percentRange) * base;
  final double dx = (maxStrike - minStrike) / (numStrikes - 1.0);
  return List<double>.generate(numStrikes, (int i) => minStrike + i * dx);
}

class SubmitBody {
  const SubmitBody({
    required this.model,
    required this.formBody,
  });

  /// The model the form was submitted against.
  ///
  /// Part of the submission rather than a separate argument at each call site:
  /// which `cf_parameters` a set of form values even *means* is a function of
  /// the model, so the two cannot be separated and stay well defined.
  final Model model;
  final Map<String, SubmitItems> formBody;

  /// Maps the form onto the typed request the calculation endpoints take.
  ///
  /// The `InputType` tag each field carries is what decides which side of the
  /// payload the value lands on — market parameters at the top level, model
  /// parameters under `cf_parameters` — so the split is declared once, here,
  /// against the tag that already encodes it. Anything that does not line up
  /// (a missing market field, a model parameter the selected model does not
  /// define) throws [RequestMappingException] instead of being dropped.
  CalculationRequest toRequest() {
    final Map<String, num> marketValues = <String, num>{};
    final Map<String, num> cfValues = <String, num>{};
    formBody.forEach((String key, SubmitItems item) {
      switch (item.inputType) {
        case InputType.Market:
          marketValues[key] = item.value;
          break;
        case InputType.Model:
          cfValues[key] = item.value;
          break;
      }
    });
    final MarketParameters market = MarketParameters.fromValues(marketValues);
    return CalculationRequest(
      model: model,
      market: market,
      cfParameters: CfParameters.forModel(model.value, cfValues),
      strikes: generateStrikes(
        asset: market.asset,
        numStrikes: NUM_STRIKES,
        percentRange: PERCENT_RANGE,
      ),
    );
  }
}
