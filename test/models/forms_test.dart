import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/components/CustomTextFields.dart';

import 'package:realoptions/models/api_request.dart';
import 'package:realoptions/models/forms.dart';
import 'package:realoptions/models/models.dart';
import 'package:realoptions/models/response.dart';

import '../support/form_fixtures.dart';

void main() {
  test('generateStrikes', () {
    expect(generateStrikes(asset: 4.0, numStrikes: 3, percentRange: 0.25),
        [3.0, 4.0, 5.0]);
    expect(generateStrikes(asset: 4.0, numStrikes: 3, percentRange: 0.5),
        [2.0, 4.0, 6.0]);
  });
  test('toRequest splits the form on its market/model tags', () {
    final CalculationRequest request =
        SubmitBody(model: heston, formBody: fullHestonForm()).toRequest();
    expect(request.model, heston);
    expect(
        request.market,
        const MarketParameters(
          asset: 4.0,
          maturity: 1.0,
          numU: 8,
          quantile: 0.05,
          rate: 0.04,
        ));
    expect(
        request.cfParameters,
        const HestonParameters(
          v0: 0.3,
          speed: 1.5,
          etaV: 1.5,
          sigma: 0.35,
          rho: -0.2,
        ));
    expect(request.strikes.length, NUM_STRIKES);
  });
  test('toRequest produces the wire payload the endpoints expect', () {
    final CalculationRequest request =
        SubmitBody(model: heston, formBody: fullHestonForm()).toRequest();
    expect(request.toJson(), {
      "asset": 4.0,
      "maturity": 1.0,
      "num_u": 8,
      "quantile": 0.05,
      "rate": 0.04,
      "cf_parameters": {
        "v0": 0.3,
        "speed": 1.5,
        "eta_v": 1.5,
        "sigma": 0.35,
        "rho": -0.2,
      },
      "strikes": request.strikes,
    });
  });
  // The old `convertSubmission()` accepted a form with one market field and
  // one model field and returned a map that simply left the rest out. Nothing
  // downstream could tell that `maturity` had never been sent. These pin the
  // opposite behaviour: the mapping refuses rather than omits.
  test('toRequest rejects a submission missing a market parameter', () {
    final Map<String, SubmitItems> form = fullHestonForm()..remove("maturity");
    expect(
        () => SubmitBody(model: heston, formBody: form).toRequest(),
        throwsA(isA<RequestMappingException>()
            .having((e) => e.message, 'message', contains('"maturity"'))));
  });
  test('toRequest rejects a model parameter the selected model does not define',
      () {
    // `lambda` belongs to Merton, not Heston. Silently dropping it would send
    // a Heston request that looks complete.
    final Map<String, SubmitItems> form = fullHestonForm()
      ..["lambda"] = SubmitItems(value: 1.0, inputType: InputType.Model);
    expect(
        () => SubmitBody(model: heston, formBody: form).toRequest(),
        throwsA(isA<RequestMappingException>()
            .having((e) => e.message, 'message', contains("lambda"))));
  });
  test('toRequest rejects a model with no typed parameter set', () {
    final Map<String, SubmitItems> form = fullHestonForm();
    expect(
        () => SubmitBody(
                model: const Model(label: "Nope", value: "nope"),
                formBody: form)
            .toRequest(),
        throwsA(isA<RequestMappingException>()));
  });
  test('equality with inputconstraint', () {
    expect(
        InputConstraint(
                defaultValue: 1.0,
                lower: 2.0,
                upper: 3.0,
                fieldType: FieldType.Float,
                name: "hello",
                inputType: InputType.Market,
                description: "body") ==
            InputConstraint(
                defaultValue: 1.0,
                lower: 2.0,
                upper: 3.0,
                fieldType: FieldType.Float,
                name: "hello",
                inputType: InputType.Market,
                description: "body"),
        true);
    expect(
        InputConstraint(
                defaultValue: 1.0,
                lower: 2.0,
                upper: 3.0,
                fieldType: FieldType.Float,
                name: "hello",
                inputType: InputType.Market,
                description: "body") ==
            InputConstraint(
                defaultValue: 1.0,
                lower: 2.0,
                upper: 4.0,
                fieldType: FieldType.Float,
                name: "hello",
                inputType: InputType.Market,
                description: "body"),
        true);
    expect(
        InputConstraint(
                defaultValue: 1.0,
                lower: 2.0,
                upper: 3.0,
                fieldType: FieldType.Float,
                name: "hello",
                inputType: InputType.Market,
                description: "body") ==
            InputConstraint(
                defaultValue: 1.0,
                lower: 2.0,
                upper: 3.0,
                fieldType: FieldType.Integer,
                name: "hello",
                inputType: InputType.Market,
                description: "body"),
        true);
    expect(
        InputConstraint(
                defaultValue: 1.0,
                lower: 2.0,
                upper: 3.0,
                fieldType: FieldType.Integer,
                name: "hello",
                inputType: InputType.Market,
                description: "body") ==
            InputConstraint(
                defaultValue: 1.0,
                lower: 2.0,
                upper: 3.0,
                fieldType: FieldType.Integer,
                name: "goodbye",
                inputType: InputType.Model,
                description: "body"),
        false);
  });
  test('equality with submititems', () {
    expect(
        SubmitItems(value: 3.0, inputType: InputType.Market) ==
            SubmitItems(value: 3.0, inputType: InputType.Market),
        true);
    expect(
        SubmitItems(value: 3.0, inputType: InputType.Market) ==
            SubmitItems(value: 4.0, inputType: InputType.Market),
        false);
    expect(
        SubmitItems(value: 3.0, inputType: InputType.Market) ==
            SubmitItems(value: 3.0, inputType: InputType.Model),
        false);
  });
  test('parse json works on the right type of map', () {
    expect(
        parseJson({
          "hello": const ParameterRange(
              lower: 3.0, upper: 4.0, type: "float", description: "hello")
        }, {
          "hello": 3.5
        }, "hello"),
        [
          InputConstraint(
              lower: 3.0,
              upper: 4.0,
              name: "hello",
              defaultValue: 3.5,
              fieldType: FieldType.Float,
              inputType: InputType.Model)
        ]);
    expect(
        parseJson({
          "hello": const ParameterRange(
              lower: 3.0, upper: 4.0, type: "integer", description: "hello")
        }, {
          "hello": 3
        }, "market"),
        [
          InputConstraint(
              lower: 3.0,
              upper: 4.0,
              name: "hello",
              defaultValue: 3,
              fieldType: FieldType.Integer,
              inputType: InputType.Market)
        ]);
  });
}
