import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:demo_api_app_flutter/services/data_models.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;


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

Future<InputConstraints> fetchConstraints(String model, String apiKey)  {
  print(model);
  print(BASE_ENDPOINT);
  print(constructUrl(BASE_ENDPOINT, API_VERSION, model, "parameters/parameter_ranges"));
  return http.get(
    constructUrl(BASE_ENDPOINT, API_VERSION, model, "parameters/parameter_ranges"), 
    headers:getHeaders(apiKey)
  ).then((response){
    //print(json.decode(response.body));
    print(response.statusCode);
    Map<String, Map<String, dynamic> > jsonMap=new Map<String, Map<String, dynamic> >.from(json.decode(response.body));
    print(jsonMap);
    if(response.statusCode==200){
      return InputConstraints.fromJson(jsonMap);
    }
    else{
      throw Exception(ErrorMessage.fromJson(json.decode(response.body)).message);
    }
    
  });
}