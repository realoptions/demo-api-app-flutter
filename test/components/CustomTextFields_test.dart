// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

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
    expect(regExp.hasMatch(".6"), true);
    expect(regExp.hasMatch("05"),
        true); //I'll keep this for now...too complicated to remove
    expect(regExp.hasMatch("5.5"), true);
    expect(regExp.hasMatch("-2"), true);
  });
  test('parses strings for float', () {
    StringUtils strUtils = StringUtils();
    expect(strUtils.getValueFromString(FieldType.Float, "1.0"), 1.0);
    expect(strUtils.getValueFromString(FieldType.Float, "-1.0"), -1.0);
    expect(strUtils.getValueFromString(FieldType.Float, "2.5"), 2.5);
  });
  test('parses strings for int', () {
    StringUtils strUtils = StringUtils();
    expect(strUtils.getValueFromString(FieldType.Integer, "1"), 1);
    expect(strUtils.getValueFromString(FieldType.Integer, "-1"), -1);
    expect(strUtils.getValueFromString(FieldType.Integer, "2"), 2);
  });
  testWidgets('shows error if blank', (WidgetTester tester) async {
    final formKey = GlobalKey<FormState>();
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(
        home: Material(
            child: Form(
                autovalidate: true,
                key: formKey,
                child: NumberTextField(
                  defaultValue: "value",
                  type: FieldType.Float,
                  onSubmit: (String v, num r) {},
                )))));
    expect(find.text('value'), findsOneWidget);
    expect(find.text("Please enter some text"), findsNothing);
    await tester.enterText(find.byType(TextFormField), "");
    await tester.pump();
    formKey.currentState.validate();
    expect(find.text('value'), findsNothing);
    expect(find.text("Please enter some text"), findsOneWidget);
  });
  testWidgets('shows error if too low', (WidgetTester tester) async {
    final formKey = GlobalKey<FormState>();
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(
        home: Material(
            child: Form(
                autovalidate: true,
                key: formKey,
                child: NumberTextField(
                  defaultValue: "value",
                  type: FieldType.Float,
                  onSubmit: (String v, num r) {},
                  lowValue: 0.0,
                  highValue: 1.0,
                )))));
    expect(find.text('value'), findsOneWidget);
    expect(find.text("Please enter some text"), findsNothing);
    await tester.enterText(find.byType(TextFormField), "-2.0");
    await tester.pump();
    formKey.currentState.validate();
    expect(find.text('value'), findsNothing);
    expect(find.text("Number must be between 0.0 and 1.0"), findsOneWidget);
  });
  testWidgets('shows error if too high', (WidgetTester tester) async {
    final formKey = GlobalKey<FormState>();
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(
        home: Material(
            child: Form(
                autovalidate: true,
                key: formKey,
                child: NumberTextField(
                  defaultValue: "value",
                  type: FieldType.Float,
                  onSubmit: (String v, num r) {},
                  lowValue: 0.0,
                  highValue: 1.0,
                )))));
    expect(find.text('value'), findsOneWidget);
    expect(find.text("Please enter some text"), findsNothing);
    await tester.enterText(find.byType(TextFormField), "2.0");
    await tester.pump();
    formKey.currentState.validate();
    expect(find.text('value'), findsNothing);
    expect(find.text("Number must be between 0.0 and 1.0"), findsOneWidget);
  });
  testWidgets('shows error if too high and integer',
      (WidgetTester tester) async {
    final formKey = GlobalKey<FormState>();
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(
        home: Material(
            child: Form(
                autovalidate: true,
                key: formKey,
                child: NumberTextField(
                  defaultValue: "value",
                  type: FieldType.Integer,
                  onSubmit: (String v, num r) {},
                  lowValue: 0,
                  highValue: 1,
                )))));
    expect(find.text('value'), findsOneWidget);
    expect(find.text("Please enter some text"), findsNothing);
    await tester.enterText(find.byType(TextFormField), "2");
    await tester.pump();
    formKey.currentState.validate();
    expect(find.text('value'), findsNothing);
    expect(find.text("Number must be between 0 and 1"), findsOneWidget);
  });
}
