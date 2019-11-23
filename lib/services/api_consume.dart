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

Map<String, Map<String, dynamic> > parseResult(http.Response response){
  if(response.statusCode==200){
    return new Map<String, Map<String, dynamic> >.from(json.decode(response.body));
  }
  else{
    throw Exception(ErrorMessage.fromJson(json.decode(response.body)).message);
  }
}

Future<InputConstraints> fetchConstraints(String model, String apiKey)  {
  return Future.wait([
     http.get(
      constructUrl(BASE_ENDPOINT, API_VERSION, "market", "parameters/parameter_ranges"), 
      headers:getHeaders(apiKey)
    ).then(parseResult),
    http.get(
      constructUrl(BASE_ENDPOINT, API_VERSION, model, "parameters/parameter_ranges"), 
      headers:getHeaders(apiKey)
    ).then(parseResult),
  ]).then((results){
    return InputConstraints.fromJson(results.reduce( (map1, map2) => map1..addAll(map2) ));
  });

}