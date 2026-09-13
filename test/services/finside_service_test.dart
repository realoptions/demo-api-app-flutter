import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:realoptions/models/api_request.dart';
import 'package:realoptions/models/forms.dart';
import 'package:realoptions/services/finside_service.dart';

import '../support/form_fixtures.dart';

/// Exercises the service against a stubbed transport rather than a stubbed
/// service, so what gets checked is the wire: the URL each call is posted to,
/// and the bytes the typed request turns into.
///
/// This is the test that matters for replacing the `Map` payloads. The types
/// prove the call sites cannot pass the wrong shape; these prove the shape
/// they pass is still the shape the API was getting before — same nesting
/// under `cf_parameters`, same top-level strikes, same endpoints.
void main() {
  late List<http.Request> sent;
  late FinsideApi api;

  setUp(() {
    sent = <http.Request>[];
    api = FinsideApi(
      apiKey: 'test-key',
      httpClient: MockClient((http.Request request) async {
        sent.add(request);
        final String path = request.url.path;
        if (path.endsWith('/density')) {
          return http.Response(
              jsonEncode([
                {'value': 1.5, 'at_point': 2.0}
              ]),
              200);
        }
        if (path.endsWith('/riskmetric')) {
          return http.Response(
              jsonEncode({'value_at_risk': 0.3, 'expected_shortfall': 0.4}),
              200);
        }
        return http.Response(
            jsonEncode([
              {'value': 3.0, 'at_point': 4.0, 'iv': 0.25}
            ]),
            200);
      }),
    );
  });

  tearDown(() {
    api.close();
  });

  test('fetchDensityAndVaR posts the typed body to density and riskmetric',
      () async {
    final CalculationRequest request = hestonRequest();
    await api.fetchDensityAndVaR(request);

    expect(sent.map((r) => r.url.path),
        containsAll(<String>['/v2/heston/density', '/v2/heston/riskmetric']));
    for (final http.Request posted in sent) {
      expect(jsonDecode(posted.body), request.toJson());
      expect(posted.headers['Authorization'], 'Bearer test-key');
    }
  });

  test('the posted body keeps market, cf_parameters and strikes distinct',
      () async {
    await api.fetchDensityAndVaR(hestonRequest());
    final Map<String, dynamic> body =
        jsonDecode(sent.first.body) as Map<String, dynamic>;

    // Market parameters at the top level...
    expect(body['asset'], 4.0);
    expect(body['num_u'], 8);
    // ...the model's nested under the wire key...
    expect(body[CfParameters.wireKey], {
      'v0': 0.3,
      'speed': 1.5,
      'eta_v': 1.5,
      'sigma': 0.35,
      'rho': -0.2,
    });
    // ...and nothing crossing over.
    expect(body.containsKey('v0'), isFalse);
    expect((body[CfParameters.wireKey] as Map).containsKey('asset'), isFalse);
    expect(body['strikes'], hasLength(NUM_STRIKES));
  });

  test('fetchOptionPrices asks for implied volatility on calls only', () async {
    await api.fetchOptionPrices(hestonRequest());

    final Map<String, http.Request> byType = {
      for (final http.Request r in sent)
        r.url.pathSegments[r.url.pathSegments.length - 2]: r
    };
    expect(byType.keys, unorderedEquals(['call', 'put']));
    expect(byType['call']!.url.queryParameters['include_implied_volatility'],
        'true');
    expect(byType['put']!.url.queryParameters['include_implied_volatility'],
        'false');
  });

  test('an error response surfaces the API message', () async {
    final FinsideApi failing = FinsideApi(
      apiKey: 'test-key',
      httpClient: MockClient((http.Request request) async =>
          http.Response(jsonEncode({'message': 'Boom'}), 500)),
    );
    addTearDown(failing.close);

    expect(failing.fetchDensityAndVaR(hestonRequest()),
        throwsA(predicate((Object? e) => e.toString().contains('Boom'))));
  });
}
