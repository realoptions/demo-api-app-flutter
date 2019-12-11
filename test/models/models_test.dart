import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/models/models.dart';

void main() {
  test('Models can be compared for equality', () {
    expect(
        Model(value: "val", label: "lab") == Model(value: "val", label: "lab"),
        true);
    expect(
        Model(value: "val1", label: "lab") == Model(value: "val", label: "lab"),
        false);
    expect(
        Model(value: "val", label: "lab") == Model(value: "val", label: "lab1"),
        false);
  });
}
