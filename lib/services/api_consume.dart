import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:demo_api_app_flutter/services/data_models.dart' as data_models;
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
      return data_models.InputConstraints.fromJson(
        Map<String, Map<String, dynamic> >.from(json.decode(response.body)),
        model
      );
    }
    else{
      throw Exception(data_models.ErrorMessage.fromJson(json.decode(response.body)).message);
    }
  };
}

Future<data_models.InputConstraints> fetchConstraints(String model, String apiKey)  {
  return Future.wait([
     http.get(
      constructUrl(BASE_ENDPOINT, API_VERSION, data_models.MARKET_NAME, "parameters/parameter_ranges"), 
      headers:getHeaders(apiKey)
    ).then(parseConstraint(data_models.MARKET_NAME)),
    http.get(
      constructUrl(BASE_ENDPOINT, API_VERSION, model, "parameters/parameter_ranges"), 
      headers:getHeaders(apiKey)
    ).then(parseConstraint(model)),
  ]).then((results){ //wish I could desctructure this
    return data_models.InputConstraints.append(results[0], results[1]);
  });
}


data_models.ModelResults parseResult(http.Response response){
  if(response.statusCode==200){
    return data_models.ModelResults.fromJson(
      List<Map<String, dynamic> >.from(json.decode(response.body))
    );
  }
  else{
    throw Exception(data_models.ErrorMessage.fromJson(json.decode(response.body)).message);
  }
}

Map convertSubmission(Map<String, SubmitItems> submittedJson, Function generateStrikes){
  Map<String, dynamic> convertedMap={};
  submittedJson.forEach((key, value){
    switch(value.inputType){
      case data_models.InputType.Market:
        convertedMap[key]=value.value;
        break;
      case data_models.InputType.Model:
        if(!convertedMap.containsKey("cf_parameters")){
          convertedMap["cf_parameters"]={};
        }
        convertedMap["cf_parameters"][key]=value.value;
        break;
    }
  });
  convertedMap["strikes"]=generateStrikes(
    convertedMap["asset"], data_models.NUM_STRIKES, data_models.PERCENT_RANGE
  );
  return convertedMap;
}

Future<data_models.ModelResults> fetchModelCalculator(
  String model, 
  String optionType, 
  String sensitivity, 
  bool includeIV,
  String apiKey, 
  Map<String, SubmitItems>  body
){
  return http.post(
    constructUrl(BASE_ENDPOINT, API_VERSION, model, p.join("calculator", optionType, sensitivity))+"?includeImpliedVolatility=$includeIV",
    headers:getHeaders(apiKey),
    body:jsonEncode(convertSubmission(body, data_models.generateStrikes)),
  ).then(parseResult);
}
Future<data_models.ModelResults> fetchModelDensity(
  String model, 
  String apiKey, 
  Map<String, SubmitItems>  body
){
  return http.post(
    constructUrl(BASE_ENDPOINT, API_VERSION, model, "density"),
    headers:getHeaders(apiKey),
    body:jsonEncode(convertSubmission(body, data_models.generateStrikes)),
  ).then(parseResult);
}

Future<Map<String, data_models.ModelResults>> fetchOptionPricesAndDensity(String model, String apiKey, Map<String, SubmitItems> body){
  return Future.wait([
    fetchModelCalculator(model, "call", "price", true, apiKey, body),
    fetchModelCalculator(model, "put", "price", false, apiKey, body),
    fetchModelDensity(model, apiKey, body),
  ]).then((results){
    return {
      "call":results[0],
      "put": results[1],
      "density": results[2],
    };
  });
}