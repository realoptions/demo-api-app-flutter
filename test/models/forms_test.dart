import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/components/CustomTextFields.dart';

import 'package:realoptions/models/forms.dart';

void main() {
  test('generateStrikes', () {
    SubmitBody body = SubmitBody(formBody: {
      "asset": SubmitItems(value: 4.0, inputType: InputType.Market),
      "v0": SubmitItems(value: 4.0, inputType: InputType.Model),
    });
    expect(body.generateStrikes(3, 0.25), [3.0, 4.0, 5.0]);
    expect(body.generateStrikes(3, 0.5), [2.0, 4.0, 6.0]);
  });
  test('convertSubmission', () {
    SubmitBody body = SubmitBody(formBody: {
      "asset": SubmitItems(value: 4.0, inputType: InputType.Market),
      "v0": SubmitItems(value: 4.0, inputType: InputType.Model),
    });
    var submission = body.convertSubmission();
    expect(submission["asset"], 4.0);
    expect(submission["cf_parameters"], {"v0": 4.0});
  });
  test('equality with inputconstraint', () {
    expect(
        InputConstraint(
                lower: 2.0,
                upper: 3.0,
                fieldType: FieldType.Float,
                name: "hello",
                inputType: InputType.Market,
                description: "body") ==
            InputConstraint(
                lower: 2.0,
                upper: 3.0,
                fieldType: FieldType.Float,
                name: "hello",
                inputType: InputType.Market,
                description: "body"),
        true);
    expect(
        InputConstraint(
                lower: 2.0,
                upper: 3.0,
                fieldType: FieldType.Float,
                name: "hello",
                inputType: InputType.Market,
                description: "body") ==
            InputConstraint(
                lower: 2.0,
                upper: 4.0,
                fieldType: FieldType.Float,
                name: "hello",
                inputType: InputType.Market,
                description: "body"),
        true);
    expect(
        InputConstraint(
                lower: 2.0,
                upper: 3.0,
                fieldType: FieldType.Float,
                name: "hello",
                inputType: InputType.Market,
                description: "body") ==
            InputConstraint(
                lower: 2.0,
                upper: 3.0,
                fieldType: FieldType.Integer,
                name: "hello",
                inputType: InputType.Market,
                description: "body"),
        true);
    expect(
        InputConstraint(
                lower: 2.0,
                upper: 3.0,
                fieldType: FieldType.Integer,
                name: "hello",
                inputType: InputType.Market,
                description: "body") ==
            InputConstraint(
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
          "hello": {
            "lower": 3.0,
            "upper": 4.0,
            "types": "float",
            "description": "hello"
          }
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
          "hello": {
            "lower": 3.0,
            "upper": 4.0,
            "types": "integer",
            "description": "hello"
          }
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
