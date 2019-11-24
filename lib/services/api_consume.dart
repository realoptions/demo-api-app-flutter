import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:demo_api_app_flutter/services/data_models.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:demo_api_app_flutter/pages/form.dart';

const String API_VERSION="v1";
const String BASE_ENDPOINT=kReleaseMode?"https://api.finside.org/realoptions":"http://10.0.2.2:8000";

Map<String, String> getHeaders(String apikey){
  return {
    'Content-type': 'application/json',
    'Accept': 'application/json',
    'x-api-Key':apikey
  };
}

String constructUrl(String base, String version, String model, String endpoint){
  return p.join(base, version, adjustModelForUrl(model), endpoint);
}

String adjustModelForUrl(String model){
  return model.toLowerCase();
}

Function parseConstraint(String model){
  return (http.Response response){
    if(response.statusCode==200){
      return InputConstraints.fromJson(
        Map<String, Map<String, dynamic> >.from(json.decode(response.body)),
        model
      );
    }
    else{
      throw Exception(ErrorMessage.fromJson(json.decode(response.body)).message);
    }
  };
}

Future<InputConstraints> fetchConstraints(String model, String apiKey)  {
  return Future.wait([
     http.get(
      constructUrl(BASE_ENDPOINT, API_VERSION, MARKET_NAME, "parameters/parameter_ranges"), 
      headers:getHeaders(apiKey)
    ).then(parseConstraint(MARKET_NAME)),
    http.get(
      constructUrl(BASE_ENDPOINT, API_VERSION, model, "parameters/parameter_ranges"), 
      headers:getHeaders(apiKey)
    ).then(parseConstraint(model)),
  ]).then((results){ //wish I could desctructure this
    return InputConstraints.append(results[0], results[1]);
  });

}


ModelResults parseResult(http.Response response){
  if(response.statusCode==200){
    print(response.body);
    return ModelResults.fromJson(
      List<Map<String, dynamic> >.from(json.decode(response.body))
    );
  }
  else{
    throw Exception(ErrorMessage.fromJson(json.decode(response.body)).message);
  }
}

Map convertSubmission(Map<String, SubmitItems> submittedJson){
  Map<String, dynamic> convertedMap={};
  submittedJson.forEach((key, value){
    switch(value.inputType){
      case InputType.Market:
        convertedMap[key]=value.value;
        break;
      case InputType.Model:
        if(!convertedMap.containsKey("cf_parameters")){
          convertedMap["cf_parameters"]={};
        }
        convertedMap["cf_parameters"][key]=value.value;
        break;
    }
  });
  return convertedMap;
}

Future<ModelResults> fetchModelCalculator(
  String model, 
  String optionType, 
  String sensitivity, 
  String apiKey, 
  Map<String, SubmitItems>  body
){
  return http.post(
    constructUrl(BASE_ENDPOINT, API_VERSION, model, p.join("calculator", optionType, sensitivity)),
    headers:getHeaders(apiKey),
    body:jsonEncode(convertSubmission(body)),
  ).then(parseResult);
}