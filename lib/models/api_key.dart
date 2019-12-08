import 'package:quiver/core.dart' show hash2;
import 'package:flutter/foundation.dart';

class ApiKey {
  final int id;
  final String key;
  ApiKey({@required this.id, @required this.key});
  Map<String, dynamic> toMap() {
    return {'id': id, 'key': key};
  }

  @override
  bool operator ==(other) {
    if (other is! ApiKey) {
      return false;
    }

    if (id != other.id) {
      return false;
    }
    if (key != other.key) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => hash2(id, key);
}
