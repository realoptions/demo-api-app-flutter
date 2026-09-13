import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/models/api_request.dart';
import 'package:realoptions/models/models.dart';

/// The four models the app offers, each with the parameter set its typed class
/// claims to send.
///
/// These round-trips are the check that the typed classes and the API agree:
/// every value survives `toJson` under the snake_case key the endpoint reads,
/// and no key is invented along the way.
void main() {
  group('CfParameters.forModel', () {
    test('dispatches to the class for the named model', () {
      expect(CfParameters.forModel('heston', const {
        'v0': 0.3,
        'speed': 1.5,
        'eta_v': 1.5,
        'sigma': 0.35,
        'rho': -0.2,
      }), isA<HestonParameters>());
      expect(CfParameters.forModel('cgmy', const {
        'c': 0.5,
        'g': 10.0,
        'm': 10.0,
        'y': 0.5,
        'sigma': 0.35,
        'v0': 0.98,
        'speed': 1.5,
        'eta_v': 1.5,
        'rho': -0.2,
      }), isA<CgmyParameters>());
      expect(CfParameters.forModel('cgmyse', const {
        'c': 0.5,
        'g': 10.0,
        'm': 10.0,
        'y': 0.5,
        'sigma': 0.35,
        'v0': 0.98,
        'speed': 0.5,
        'eta_v': 0.2,
      }), isA<CgmyseParameters>());
      expect(CfParameters.forModel('merton', const {
        'lambda': 1.0,
        'mu_l': -0.2,
        'sig_l': 1.0,
        'sigma': 0.35,
        'v0': 0.98,
        'speed': 1.5,
        'eta_v': 1.5,
        'rho': -0.2,
      }), isA<MertonParameters>());
    });

    test('refuses a model it has no typed set for', () {
      expect(() => CfParameters.forModel('vasicek', const {}),
          throwsA(isA<RequestMappingException>()));
    });

    test('every model in MODEL_CHOICES has a typed parameter set', () {
      // Guards the drift that matters most: a model added to the picker without
      // a matching CfParameters class would fail at submit time, in front of a
      // user, rather than here.
      for (final Model model in MODEL_CHOICES) {
        // A model with no typed class says so outright; anything else means the
        // dispatch found the class and got as far as checking its parameters.
        expect(() => CfParameters.forModel(model.value, const {}),
            throwsA(isA<RequestMappingException>().having(
                (e) => e.message,
                'message',
                isNot(startsWith('no typed cf_parameters')))),
            reason: '${model.value} is selectable but has no typed parameters');
      }
    });
  });

  group('toJson round-trips the wire keys', () {
    test('heston', () {
      expect(const HestonParameters(
        v0: 0.3,
        speed: 1.5,
        etaV: 1.5,
        sigma: 0.35,
        rho: -0.2,
      ).toJson(), {
        'v0': 0.3,
        'speed': 1.5,
        'eta_v': 1.5,
        'sigma': 0.35,
        'rho': -0.2,
      });
    });

    test('cgmy', () {
      expect(const CgmyParameters(
        c: 0.5,
        g: 10.0,
        m: 10.0,
        y: 0.5,
        sigma: 0.35,
        v0: 0.98,
        speed: 1.5,
        etaV: 1.5,
        rho: -0.2,
      ).toJson(), {
        'c': 0.5,
        'g': 10.0,
        'm': 10.0,
        'y': 0.5,
        'sigma': 0.35,
        'v0': 0.98,
        'speed': 1.5,
        'eta_v': 1.5,
        'rho': -0.2,
      });
    });

    test('cgmyse', () {
      expect(const CgmyseParameters(
        c: 0.5,
        g: 10.0,
        m: 10.0,
        y: 0.5,
        sigma: 0.35,
        v0: 0.98,
        speed: 0.5,
        etaV: 0.2,
      ).toJson(), {
        'c': 0.5,
        'g': 10.0,
        'm': 10.0,
        'y': 0.5,
        'sigma': 0.35,
        'v0': 0.98,
        'speed': 0.5,
        'eta_v': 0.2,
      });
    });

    test('merton', () {
      expect(const MertonParameters(
        lambda: 1.0,
        muL: -0.2,
        sigL: 1.0,
        sigma: 0.35,
        v0: 0.98,
        speed: 1.5,
        etaV: 1.5,
        rho: -0.2,
      ).toJson(), {
        'lambda': 1.0,
        'mu_l': -0.2,
        'sig_l': 1.0,
        'sigma': 0.35,
        'v0': 0.98,
        'speed': 1.5,
        'eta_v': 1.5,
        'rho': -0.2,
      });
    });

    test('market', () {
      expect(const MarketParameters(
        asset: 50.0,
        maturity: 1.0,
        numU: 8,
        quantile: 0.05,
        rate: 0.04,
      ).toJson(), {
        'asset': 50.0,
        'maturity': 1.0,
        'num_u': 8,
        'quantile': 0.05,
        'rate': 0.04,
      });
    });
  });

  group('missing and extra parameters are reported, not dropped', () {
    test('a missing market parameter names itself', () {
      expect(
          () => MarketParameters.fromValues(const {
                'asset': 50.0,
                'maturity': 1.0,
                'quantile': 0.05,
                'rate': 0.04,
              }),
          throwsA(isA<RequestMappingException>()
              .having((e) => e.message, 'message', contains('"num_u"'))));
    });

    test('an unrecognised market parameter names itself', () {
      expect(
          () => MarketParameters.fromValues(const {
                'asset': 50.0,
                'maturity': 1.0,
                'num_u': 8,
                'quantile': 0.05,
                'rate': 0.04,
                'risk_free': 0.04,
              }),
          throwsA(isA<RequestMappingException>()
              .having((e) => e.message, 'message', contains('risk_free'))));
    });

    test('a misspelled cf parameter surfaces as a missing one', () {
      // `sigma` written as `sigm` used to be the silent case: the map kept a
      // key nobody reads and the real one never arrived.
      expect(
          () => HestonParameters.fromValues(const {
                'v0': 0.3,
                'speed': 1.5,
                'eta_v': 1.5,
                'sigm': 0.35,
                'rho': -0.2,
              }),
          throwsA(isA<RequestMappingException>()
              .having((e) => e.message, 'message', contains('"sigma"'))));
    });
  });

  test('CalculationRequest nests cf_parameters and keeps strikes alongside market',
      () {
    const CalculationRequest request = CalculationRequest(
      model: Model(label: "Heston", value: "heston"),
      market: MarketParameters(
        asset: 50.0,
        maturity: 1.0,
        numU: 8,
        quantile: 0.05,
        rate: 0.04,
      ),
      cfParameters: HestonParameters(
        v0: 0.3,
        speed: 1.5,
        etaV: 1.5,
        sigma: 0.35,
        rho: -0.2,
      ),
      strikes: [25.0, 50.0, 75.0],
    );
    final Map<String, dynamic> json = request.toJson();
    expect(json[CfParameters.wireKey], isA<Map<String, num>>());
    expect(json['strikes'], [25.0, 50.0, 75.0]);
    // Market parameters sit at the top level, not nested.
    expect(json['asset'], 50.0);
    // And the two blocks stay separate: no market key leaks into cf_parameters
    // and no cf key leaks out of it.
    expect(json.containsKey('v0'), isFalse);
    expect(
        (json[CfParameters.wireKey] as Map).containsKey('asset'), isFalse);
  });
}
