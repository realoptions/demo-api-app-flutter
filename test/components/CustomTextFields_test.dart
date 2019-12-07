// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:realoptions/components/CustomTextFields.dart';

void main() {
  test('getRegex returns the correct regex depending on type', () {
    StringUtils strUtils = StringUtils();
    expect(strUtils.getRegex(FieldType.Float),
        r"[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)");
    expect(strUtils.getRegex(FieldType.Integer), r"^[1-9]\d*$");
  });
  test('regex for integer', () {
    StringUtils strUtils = StringUtils();
    var regExp = RegExp(strUtils.getRegex(FieldType.Integer));
    expect(regExp.hasMatch("5"), true);
    expect(regExp.hasMatch("5.0"), false);
    expect(regExp.hasMatch("05"), false);
    expect(regExp.hasMatch("5.5"), false);
    expect(regExp.hasMatch("-2"), false); //only positive
  });
  test('regex for float', () {
    StringUtils strUtils = StringUtils();
    var regExp = RegExp(strUtils.getRegex(FieldType.Float));
    expect(regExp.hasMatch("5"), true);
    expect(regExp.hasMatch("5.0"), true);
    expect(regExp.hasMatch("05"),
        true); //I'll keep this for now...too complicated to remove
    expect(regExp.hasMatch("5.5"), true);
    expect(regExp.hasMatch("-2"), true);
  });
}
