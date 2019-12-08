import 'package:quiver/core.dart' show hash2;
import 'package:flutter/foundation.dart';

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
