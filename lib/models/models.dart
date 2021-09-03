import 'package:quiver/core.dart' show hash2;
import 'package:flutter/foundation.dart';

const List<Model> MODEL_CHOICES = const <Model>[
  const Model(label: "Heston", value: "heston"),
  const Model(label: "CGMY", value: "cgmy"),
  const Model(label: "CGMYSE", value: "cgmyse"),
  const Model(label: "Merton", value: "merton")
];

const Map<String, Map<String, double>> DEFAULT_VALUES = {
  "heston": {
    "v0": 0.30,
    "speed": 1.5,
    "eta_v": 1.5,
    "sigma": 0.35,
    "rho": -0.2,
  },
  "cgmy": {
    "c": 0.5,
    "g": 10.0,
    "m": 10.0,
    "y": 0.5,
    "sigma": 0.35,
    "v0": 0.98,
    "speed": 1.5,
    "eta_v": 1.5,
    "rho": -0.2,
  },
  "cgmyse": {
    "c": 0.5,
    "g": 10.0,
    "m": 10.0,
    "y": 0.5,
    "sigma": 0.35,
    "v0": 0.98,
    "speed": 0.5,
    "eta_v": 0.2,
  },
  "merton": {
    "lambda": 1.0,
    "mu_l": -0.2,
    "sig_l": 1.0,
    "sigma": 0.35,
    "v0": 0.98,
    "speed": 1.5,
    "eta_v": 1.5,
    "rho": -0.2,
  },
  "market": {
    "asset": 50.0,
    "maturity": 1.0,
    "num_u": 8,
    "quantile": 0.05,
    "rate": 0.04
  },
};

class Model {
  final String value;
  final String label;
  const Model({@required this.value, @required this.label});
  @override
  bool operator ==(other) {
    if (other is! Model) {
      return false;
    }
    if (value != other.value) {
      return false;
    }
    if (label != other.label) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => hash2(value, label);
}
