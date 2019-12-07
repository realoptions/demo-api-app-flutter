import 'package:flutter_test/flutter_test.dart';

import 'package:demo_api_app_flutter/utils/chart_utils.dart';

void main() {
  test('gets axis correctly', () {
    var axis = getAxis(1.0, 5.0);
    expect(axis.length, 5);
    expect(axis[0].value, 1.0);
    expect(axis[1].value, 2.0);
    expect(axis[2].value, 3.0);
    expect(axis[3].value, 4.0);
    expect(axis[4].value, 5.0);
  });
}
