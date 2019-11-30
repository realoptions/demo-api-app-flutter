import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:demo_api_app_flutter/models/forms.dart';
import 'package:demo_api_app_flutter/models/response.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const String API_VERSION = "v1";
const String BASE_ENDPOINT = kReleaseMode
    ? "https://api.finside.org/realoptions"
    : "http://10.0.2.2:8000";

Map<String, String> getHeaders(String apikey) {
  return {
    'Content-type': 'application/json',
    'Accept': 'application/json',
    'x-api-Key': apikey
  };
}

String constructUrl(
    String base, String version, String model, String endpoint) {
  return p.join(base, version, model, endpoint);
}

List<InputConstraint> Function(http.Response) parseConstraint(String model) {
  return (http.Response response) {
    if (response.statusCode == 200) {
      return parseJson(
          Map<String, Map<String, dynamic>>.from(json.decode(response.body)),
          model);
    } else {
      throw Exception(
          ErrorMessage.fromJson(json.decode(response.body)).message);
    }
  };
}

Future<List<InputConstraint>> fetchConstraints(String model, String apiKey) {
  return Future.wait([
    http
        .get(
            constructUrl(BASE_ENDPOINT, API_VERSION, MARKET_NAME,
                "parameters/parameter_ranges"),
            headers: getHeaders(apiKey))
        .then(parseConstraint(MARKET_NAME)),
    http
        .get(
            constructUrl(BASE_ENDPOINT, API_VERSION, model,
                "parameters/parameter_ranges"),
            headers: getHeaders(apiKey))
        .then(parseConstraint(model)),
  ]).then((results) {
    //wish I could desctructure this
    return [...results[0], ...results[1]];
  });
}

List<ModelResult> parseResult(http.Response response) {
  if (response.statusCode == 200) {
    return List<Map<String, dynamic>>.from(json.decode(response.body))
        .map((item) => ModelResult.fromJson(item))
        .toList();
  } else {
    throw Exception(ErrorMessage.fromJson(json.decode(response.body)).message);
  }
}

Future<List<ModelResult>> fetchModelCalculator(String model, String optionType,
    String sensitivity, bool includeIV, String apiKey, Map body) {
  return http
      .post(
        constructUrl(BASE_ENDPOINT, API_VERSION, model,
                p.join("calculator", optionType, sensitivity)) +
            "?includeImpliedVolatility=$includeIV",
        headers: getHeaders(apiKey),
        body: jsonEncode(body),
      )
      .then(parseResult);
}

Future<List<ModelResult>> fetchModelDensity(
    String model, String apiKey, Map body) {
  return http
      .post(constructUrl(BASE_ENDPOINT, API_VERSION, model, "density"),
          headers: getHeaders(apiKey), body: jsonEncode(body))
      .then(parseResult);
}

Future<Map<String, List<ModelResult>>> fetchOptionPrices(
    String model, String apiKey, Map body) {
  return Future.wait([
    fetchModelCalculator(model, "call", "price", true, apiKey, body),
    fetchModelCalculator(model, "put", "price", false, apiKey, body),
  ]).then((results) {
    return {
      "call": results[0],
      "put": results[1],
    };
  });
}
