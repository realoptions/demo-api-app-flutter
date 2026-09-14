import 'package:realoptions/components/CustomTextFields.dart';
import 'package:realoptions/models/api_request.dart';
import 'package:realoptions/models/forms.dart';
import 'package:realoptions/models/models.dart';

const Model heston = Model(label: "Heston", value: "heston");

/// A complete, internally consistent Heston submission: the five market
/// fields plus the five parameters Heston defines.
///
/// Fresh instance per call — several tests mutate a copy of this to remove or
/// add a field, and a shared const map would make them interfere.
Map<String, SubmitItems> fullHestonForm() => {
      "asset": SubmitItems(value: 4.0, inputType: InputType.Market),
      "maturity": SubmitItems(value: 1.0, inputType: InputType.Market),
      "num_u": SubmitItems(value: 8, inputType: InputType.Market),
      "quantile": SubmitItems(value: 0.05, inputType: InputType.Market),
      "rate": SubmitItems(value: 0.04, inputType: InputType.Market),
      "v0": SubmitItems(value: 0.3, inputType: InputType.Model),
      "speed": SubmitItems(value: 1.5, inputType: InputType.Model),
      "eta_v": SubmitItems(value: 1.5, inputType: InputType.Model),
      "sigma": SubmitItems(value: 0.35, inputType: InputType.Model),
      "rho": SubmitItems(value: -0.2, inputType: InputType.Model),
    };

/// The request the app would build from [fullHestonForm].
///
/// Built through the real `toRequest` mapping rather than hand-rolled, so a
/// test written against this object exercises the same path the submit button
/// takes — including the market/cf split.
CalculationRequest hestonRequest() =>
    SubmitBody(model: heston, formBody: fullHestonForm()).toRequest();

/// The constraints a Heston run returns, matching [fullHestonForm] field for
/// field so the rendered form and the expected submission agree.
///
/// A widget test that drives the submit button needs the whole set. When the
/// body was an unvalidated `Map` a one-field form was enough; now a form that
/// renders only `asset` correctly fails the mapping for the four market
/// parameters it never had, so the fixture has to describe what the API
/// actually sends back.
List<InputConstraint> fullHestonConstraints() => [
      for (final MapEntry<String, SubmitItems> entry
          in fullHestonForm().entries)
        InputConstraint(
          name: entry.key,
          fieldType:
              entry.value.value is int ? FieldType.Integer : FieldType.Float,
          inputType: entry.value.inputType,
          defaultValue: entry.value.value,
          // Wide bounds: the fixture's job is to let every default through,
          // not to re-derive the API's per-parameter limits.
          lower: -1000,
          upper: 1000,
          description: entry.key,
        ),
    ];
