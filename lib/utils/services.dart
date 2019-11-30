import 'package:demo_api_app_flutter/models/forms.dart';

Map convertSubmission(
    Map<String, SubmitItems> submittedJson, Function generateStrikes) {
  Map<String, dynamic> convertedMap = {};
  submittedJson.forEach((key, value) {
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
  convertedMap["strikes"] =
      generateStrikes(convertedMap["asset"], NUM_STRIKES, PERCENT_RANGE);
  return convertedMap;
}
