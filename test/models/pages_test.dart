import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/models/pages.dart';

void main() {
  test('PageState can be compared for equality', () {
    expect(
        PageState(index: 0, showBadges: [false, false, false]) ==
            PageState(index: 0, showBadges: [false, false, false]),
        true);
    expect(
        PageState(index: 1, showBadges: [false, false, false]) ==
            PageState(index: 0, showBadges: [false, false, false]),
        false);
    expect(
        PageState(index: 0, showBadges: [false, true, false]) ==
            PageState(index: 0, showBadges: [false, false, false]),
        false);
  });
}
