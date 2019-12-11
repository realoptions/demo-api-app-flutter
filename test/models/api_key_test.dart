import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/models/api_key.dart';

void main() {
  test('ApiKeys can be compared for equality', () {
    expect(ApiKey(id: 4, key: "apikey") == ApiKey(id: 4, key: "apikey"), true);
    expect(ApiKey(id: 4, key: "apikey") == ApiKey(id: 5, key: "apikey"), false);
    expect(
        ApiKey(id: 4, key: "apikey") == ApiKey(id: 4, key: "apikeys"), false);
  });
  test('ApiKeys returns map', () {
    expect(ApiKey(id: 4, key: "apikey").toMap(), {"id": 4, "key": "apikey"});
  });
}
