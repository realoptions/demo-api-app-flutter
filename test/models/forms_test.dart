import 'package:flutter_test/flutter_test.dart';
//import "dart:async";
import 'package:demo_api_app_flutter/models/forms.dart';

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
}
