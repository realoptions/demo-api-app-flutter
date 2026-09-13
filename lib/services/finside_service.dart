import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:realoptions/models/api_request.dart';
import 'package:realoptions/models/forms.dart';
import 'package:realoptions/models/models.dart';
import 'package:realoptions/models/response.dart';
import 'package:http/http.dart' as http;

const String API_VERSION = "v2";
const String BASE_ENDPOINT = "https://api2.finside.org";

class FinsideApi {
  /// Creates the API service.
  ///
  /// [httpClient] is injectable so the transport can be swapped without touching
  /// the call sites. Previously every request went through the top-level
  /// `http.get`/`http.post` functions, which bind to a process-wide default
  /// client and expose no handle to stub — the service could only be tested by
  /// mocking this class rather than by exercising it. With a client injected (a
  /// `MockClient` in tests, a real one in the app) the wire behaviour — URL
  /// construction, headers, status handling — becomes testable directly.
  ///
  /// When no client is supplied the service owns one and [close] disposes it.
  FinsideApi({required this.apiKey, http.Client? httpClient})
      : _client = httpClient ?? http.Client(),
        _ownsClient = httpClient == null;

  final String apiKey;
  final http.Client _client;
  final bool _ownsClient;

  /// Releases the underlying HTTP client.
  ///
  /// Only closes a client this instance created; an injected client belongs to
  /// whoever injected it and is left alone, so a shared client cannot be closed
  /// out from under another owner.
  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }

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
        final Map<String, dynamic> decoded = json.decode(response.body);
        final Map<String, ParameterRange> ranges = decoded.map(
            (String key, dynamic value) => MapEntry(
                key,
                ParameterRange.fromJson(Map<String, dynamic>.from(value))));
        return parseJson(ranges, DEFAULT_VALUES[model]!, model);
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
      _client
          .get(
              Uri.parse(p.join(BASE_ENDPOINT, API_VERSION, MARKET_NAME,
                  "parameters/parameter_ranges")),
              headers: _getHeaders())
          .then(_parseConstraint(MARKET_NAME)),
      _client
          .get(
              Uri.parse(p.join(BASE_ENDPOINT, API_VERSION, model,
                  "parameters/parameter_ranges")),
              headers: _getHeaders())
          .then(_parseConstraint(model)),
    ]).then((results) {
      //wish I could desctructure this
      return [...results[0], ...results[1]];
    });
  }

  Future<List<ModelResult>> _fetchModelCalculator(CalculationRequest request,
      String optionType, String sensitivity, bool includeIV) {
    return _client
        .post(
          Uri.parse(p.join(BASE_ENDPOINT, API_VERSION, request.model.value,
                  "calculator", optionType, sensitivity) +
              "?include_implied_volatility=$includeIV"),
          headers: _getHeaders(),
          body: jsonEncode(request.toJson()),
        )
        .then(_parseResult);
  }

  Future<List<ModelResult>> _fetchModelDensity(CalculationRequest request) {
    return _client
        .post(
            Uri.parse(p.join(BASE_ENDPOINT, API_VERSION, request.model.value,
                "density")),
            headers: _getHeaders(),
            body: jsonEncode(request.toJson()))
        .then(_parseResult);
  }

  Future<VaRResult> _fetchModelValueAtRisk(CalculationRequest request) {
    return _client
        .post(
            Uri.parse(p.join(BASE_ENDPOINT, API_VERSION, request.model.value,
                "riskmetric")),
            headers: _getHeaders(),
            body: jsonEncode(request.toJson()))
        .then(_parseMetric);
  }

  Future<DensityAndVaR> fetchDensityAndVaR(CalculationRequest request) {
    // The two futures have different result types, so `Future.wait` infers
    // `Object` for the list element and the pair has to be cast back out here.
    return Future.wait<Object>([
      _fetchModelDensity(request),
      _fetchModelValueAtRisk(request)
    ]).then((results) => DensityAndVaR(
        density: results[0] as List<ModelResult>,
        riskMetrics: results[1] as VaRResult));
  }

  Future<OptionPrices> fetchOptionPrices(CalculationRequest request) {
    // Both legs are the same type now, so unlike fetchDensityAndVaR the pair
    // comes back typed and needs no cast out of `Object`.
    return Future.wait([
      _fetchModelCalculator(request, "call", "price", true),
      _fetchModelCalculator(request, "put", "price", false),
    ]).then((results) => OptionPrices(calls: results[0], puts: results[1]));
  }
}
