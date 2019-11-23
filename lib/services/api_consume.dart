import 'dart:convert';
import 'package:demo_api_app_flutter/services/data_models.dart';
import 'package:http/http.dart' as http;

const String BASE_ENDPOINT="https://api.finside.org/realoptions/v1";

Map<String, String> getHeaders(String apikey){
  return {
    'Content-type': 'application/json',
    'Accept': 'application/json',
    'x-api-Key':apikey
  };
}

Future<InputConstraints> fetchConstraints(String model, String apiKey)  {
  print(model);
  return http.get(
    BASE_ENDPOINT+"/"+model.toLowerCase()+"/parameters/parameter_ranges", 
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