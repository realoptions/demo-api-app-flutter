import 'package:equatable/equatable.dart';
import 'package:realoptions/models/models.dart';

/// A submitted form that cannot be mapped onto the typed wire request.
///
/// This replaces a silence. The payload used to be assembled into a plain
/// `Map`, so a parameter the form did not carry simply never appeared in it
/// and a misspelled key produced a request that looked perfectly well formed
/// and was wrong — the API either filled the gap with its own default or
/// failed with an error pointing nowhere near the cause. Every mapping through
/// the types below goes the other way: the name that is missing or unknown is
/// reported at the boundary where it was noticed.
class RequestMappingException implements Exception {
  const RequestMappingException(this.message);

  final String message;

  @override
  String toString() => 'Exception: $message';
}

/// Reads the numbers a request needs out of a form's values, remembering which
/// ones it has consumed.
///
/// The leftover check is the reason this exists rather than a plain `map[key]!`:
/// a form that grows a field the request does not know about is a divergence
/// between the form and the API contract, and it should surface as this error
/// instead of as a parameter that quietly stops being sent.
class _ValueReader {
  _ValueReader(this._owner, Map<String, num> values)
      : _remaining = Map<String, num>.of(values);

  final String _owner;
  final Map<String, num> _remaining;

  num take(String key) {
    final num? value = _remaining.remove(key);
    if (value == null) {
      throw RequestMappingException(
          '$_owner is missing required parameter "$key"');
    }
    return value;
  }

  void done() {
    if (_remaining.isNotEmpty) {
      final List<String> extra = _remaining.keys.toList()..sort();
      throw RequestMappingException(
          '$_owner has no parameter named ${extra.join(', ')}');
    }
  }
}

/// Inputs that describe the market and the run.
///
/// These are the parameters the API expects at the *top level* of the payload,
/// as distinct from [CfParameters], which it expects nested. Before the two
/// were told apart only by the branch in `convertSubmission()` that sorted
/// them into different parts of a map; now the difference is carried by the
/// types themselves, so a market value cannot end up in the model block
/// without a type error.
class MarketParameters extends Equatable {
  const MarketParameters({
    required this.asset,
    required this.maturity,
    required this.numU,
    required this.quantile,
    required this.rate,
  });

  /// Builds the market block from wire-keyed values (as produced by splitting a
  /// submitted form on its `InputType.Market` tag).
  factory MarketParameters.fromValues(Map<String, num> values) {
    final _ValueReader reader = _ValueReader('market', values);
    final MarketParameters parameters = MarketParameters(
      asset: reader.take('asset'),
      maturity: reader.take('maturity'),
      numU: reader.take('num_u'),
      quantile: reader.take('quantile'),
      rate: reader.take('rate'),
    );
    reader.done();
    return parameters;
  }

  final num asset;
  final num maturity;
  final num numU;
  final num quantile;
  final num rate;

  Map<String, num> toJson() => {
        'asset': asset,
        'maturity': maturity,
        'num_u': numU,
        'quantile': quantile,
        'rate': rate,
      };

  @override
  List<Object> get props => [asset, maturity, numU, quantile, rate];
}

/// A model's characteristic-function parameters: the shape of the process,
/// as distinct from the market inputs in [MarketParameters].
abstract class CfParameters extends Equatable {
  const CfParameters();

  /// Key the API nests these under, as opposed to the market parameters which
  /// sit at the top level of the payload. Named once, here, rather than
  /// spelled at each place that assembles a body.
  static const String wireKey = 'cf_parameters';

  Map<String, num> toJson();

  /// The parameter set [model] sends, built from the `InputType.Model` values
  /// of a submitted form.
  ///
  /// A model with no typed set here is an error rather than a fallthrough:
  /// sending an empty `cf_parameters` block would ask the API for something
  /// nobody intended.
  static CfParameters forModel(String model, Map<String, num> values) {
    switch (model) {
      case HestonParameters.modelKey:
        return HestonParameters.fromValues(values);
      case CgmyParameters.modelKey:
        return CgmyParameters.fromValues(values);
      case CgmyseParameters.modelKey:
        return CgmyseParameters.fromValues(values);
      case MertonParameters.modelKey:
        return MertonParameters.fromValues(values);
      default:
        throw RequestMappingException(
            'no typed cf_parameters defined for model "$model"');
    }
  }
}

class HestonParameters extends CfParameters {
  const HestonParameters({
    required this.v0,
    required this.speed,
    required this.etaV,
    required this.sigma,
    required this.rho,
  });

  static const String modelKey = 'heston';

  factory HestonParameters.fromValues(Map<String, num> values) {
    final _ValueReader reader = _ValueReader('$modelKey cf_parameters', values);
    final HestonParameters parameters = HestonParameters(
      v0: reader.take('v0'),
      speed: reader.take('speed'),
      etaV: reader.take('eta_v'),
      sigma: reader.take('sigma'),
      rho: reader.take('rho'),
    );
    reader.done();
    return parameters;
  }

  final num v0;
  final num speed;
  final num etaV;
  final num sigma;
  final num rho;

  @override
  Map<String, num> toJson() => {
        'v0': v0,
        'speed': speed,
        'eta_v': etaV,
        'sigma': sigma,
        'rho': rho,
      };

  @override
  List<Object> get props => [v0, speed, etaV, sigma, rho];
}

class CgmyParameters extends CfParameters {
  const CgmyParameters({
    required this.c,
    required this.g,
    required this.m,
    required this.y,
    required this.sigma,
    required this.v0,
    required this.speed,
    required this.etaV,
    required this.rho,
  });

  static const String modelKey = 'cgmy';

  factory CgmyParameters.fromValues(Map<String, num> values) {
    final _ValueReader reader = _ValueReader('$modelKey cf_parameters', values);
    final CgmyParameters parameters = CgmyParameters(
      c: reader.take('c'),
      g: reader.take('g'),
      m: reader.take('m'),
      y: reader.take('y'),
      sigma: reader.take('sigma'),
      v0: reader.take('v0'),
      speed: reader.take('speed'),
      etaV: reader.take('eta_v'),
      rho: reader.take('rho'),
    );
    reader.done();
    return parameters;
  }

  final num c;
  final num g;
  final num m;
  final num y;
  final num sigma;
  final num v0;
  final num speed;
  final num etaV;
  final num rho;

  @override
  Map<String, num> toJson() => {
        'c': c,
        'g': g,
        'm': m,
        'y': y,
        'sigma': sigma,
        'v0': v0,
        'speed': speed,
        'eta_v': etaV,
        'rho': rho,
      };

  @override
  List<Object> get props => [c, g, m, y, sigma, v0, speed, etaV, rho];
}

class CgmyseParameters extends CfParameters {
  const CgmyseParameters({
    required this.c,
    required this.g,
    required this.m,
    required this.y,
    required this.sigma,
    required this.v0,
    required this.speed,
    required this.etaV,
  });

  static const String modelKey = 'cgmyse';

  factory CgmyseParameters.fromValues(Map<String, num> values) {
    final _ValueReader reader = _ValueReader('$modelKey cf_parameters', values);
    final CgmyseParameters parameters = CgmyseParameters(
      c: reader.take('c'),
      g: reader.take('g'),
      m: reader.take('m'),
      y: reader.take('y'),
      sigma: reader.take('sigma'),
      v0: reader.take('v0'),
      speed: reader.take('speed'),
      etaV: reader.take('eta_v'),
    );
    reader.done();
    return parameters;
  }

  final num c;
  final num g;
  final num m;
  final num y;
  final num sigma;
  final num v0;
  final num speed;
  final num etaV;

  @override
  Map<String, num> toJson() => {
        'c': c,
        'g': g,
        'm': m,
        'y': y,
        'sigma': sigma,
        'v0': v0,
        'speed': speed,
        'eta_v': etaV,
      };

  @override
  List<Object> get props => [c, g, m, y, sigma, v0, speed, etaV];
}

class MertonParameters extends CfParameters {
  const MertonParameters({
    required this.lambda,
    required this.muL,
    required this.sigL,
    required this.sigma,
    required this.v0,
    required this.speed,
    required this.etaV,
    required this.rho,
  });

  static const String modelKey = 'merton';

  factory MertonParameters.fromValues(Map<String, num> values) {
    final _ValueReader reader = _ValueReader('$modelKey cf_parameters', values);
    final MertonParameters parameters = MertonParameters(
      lambda: reader.take('lambda'),
      muL: reader.take('mu_l'),
      sigL: reader.take('sig_l'),
      sigma: reader.take('sigma'),
      v0: reader.take('v0'),
      speed: reader.take('speed'),
      etaV: reader.take('eta_v'),
      rho: reader.take('rho'),
    );
    reader.done();
    return parameters;
  }

  final num lambda;
  final num muL;
  final num sigL;
  final num sigma;
  final num v0;
  final num speed;
  final num etaV;
  final num rho;

  @override
  Map<String, num> toJson() => {
        'lambda': lambda,
        'mu_l': muL,
        'sig_l': sigL,
        'sigma': sigma,
        'v0': v0,
        'speed': speed,
        'eta_v': etaV,
        'rho': rho,
      };

  @override
  List<Object> get props => [lambda, muL, sigL, sigma, v0, speed, etaV, rho];
}

/// Everything one of the calculation endpoints needs for one run: which model,
/// the market inputs, that model's characteristic-function parameters, and the
/// strike ladder the results are computed on.
///
/// This is the object that used to be a `Map` travelling from the form through
/// two bloc events into five service methods. Carrying it as a type means the
/// payload's shape — market parameters at the top level, the model's under
/// `cf_parameters`, the strikes alongside the market ones — is decided once,
/// in [toJson], by the class that owns it.
class CalculationRequest extends Equatable {
  const CalculationRequest({
    required this.model,
    required this.market,
    required this.cfParameters,
    required this.strikes,
  });

  final Model model;
  final MarketParameters market;
  final CfParameters cfParameters;
  final List<double> strikes;

  Map<String, dynamic> toJson() => {
        ...market.toJson(),
        CfParameters.wireKey: cfParameters.toJson(),
        'strikes': strikes,
      };

  @override
  List<Object> get props => [model, market, cfParameters, strikes];
}
