import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:realoptions/models/forms.dart';
import 'package:realoptions/models/models.dart';
import 'package:realoptions/models/response.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const String API_VERSION = "v2";
const String BASE_ENDPOINT = "https://api2.finside.org";

class FinsideApi {
  FinsideApi({@required this.apiKey});
  final String apiKey;
  Map<String, String> _getHeaders() {
    return {
      'Content-type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $apiKey'
    };
  }

  List<InputConstraint> Function(http.Response) _parseConstraint(String model) {
    return (http.Response response) {
      if (response.statusCode == 200) {
        return parseJson(
            Map<String, Map<String, dynamic>>.from(json.decode(response.body)),
            DEFAULT_VALUES[model],
            model);
      } else {
        throw Exception(
            ErrorMessage.fromJson(json.decode(response.body)).message);
      }
    };
  }

  List<ModelResult> _parseResult(http.Response response) {
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body))
          .map((item) => ModelResult.fromJson(item))
          .toList();
    } else {
      throw Exception(
          ErrorMessage.fromJson(json.decode(response.body)).message);
    }
  }

  VaRResult _parseMetric(http.Response response) {
    if (response.statusCode == 200) {
      return VaRResult.fromJson(json.decode(response.body));
    } else {
      throw Exception(
          ErrorMessage.fromJson(json.decode(response.body)).message);
    }
  }

  Future<List<InputConstraint>> fetchConstraints(String model) {
    return Future.wait([
      http
          .get(
              p.join(BASE_ENDPOINT, API_VERSION, MARKET_NAME,
                  "parameters/parameter_ranges"),
              headers: _getHeaders())
          .then(_parseConstraint(MARKET_NAME)),
      http
          .get(
              p.join(BASE_ENDPOINT, API_VERSION, model,
                  "parameters/parameter_ranges"),
              headers: _getHeaders())
          .then(_parseConstraint(model)),
    ]).then((results) {
      //wish I could desctructure this
      return [...results[0], ...results[1]];
    });
  }

  Future<List<ModelResult>> _fetchModelCalculator(String model,
      String optionType, String sensitivity, bool includeIV, Map body) {
    return http
        .post(
          p.join(BASE_ENDPOINT, API_VERSION, model, "calculator", optionType,
                  sensitivity) +
              "?include_implied_volatility=$includeIV",
          headers: _getHeaders(),
          body: jsonEncode(body),
        )
        .then(_parseResult);
  }

  Future<List<ModelResult>> _fetchModelDensity(String model, Map body) {
    return http
        .post(p.join(BASE_ENDPOINT, API_VERSION, model, "density"),
            headers: _getHeaders(), body: jsonEncode(body))
        .then(_parseResult);
  }

  Future<VaRResult> _fetchModelValueAtRisk(String model, Map body) {
    return http
        .post(p.join(BASE_ENDPOINT, API_VERSION, model, "riskmetric"),
            headers: _getHeaders(), body: jsonEncode(body))
        .then(_parseMetric);
  }

  Future<DensityAndVaR> fetchDensityAndVaR(String model, Map body) {
    return Future.wait([
      _fetchModelDensity(model, body),
      _fetchModelValueAtRisk(model, body)
    ]).then((results) =>
        DensityAndVaR(density: results[0], riskMetrics: results[1]));
  }

  Future<Map<String, List<ModelResult>>> fetchOptionPrices(
      String model, Map body) {
    return Future.wait([
      _fetchModelCalculator(model, "call", "price", true, body),
      _fetchModelCalculator(model, "put", "price", false, body),
    ]).then((results) => {
          "call": results[0],
          "put": results[1],
        });
  }
}
