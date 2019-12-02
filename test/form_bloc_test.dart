import 'package:demo_api_app_flutter/components/CustomTextFields.dart';
import 'package:demo_api_app_flutter/models/forms.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_api_app_flutter/blocs/form_bloc.dart';

void main() {
  test(
      'gets constraint default if not part of defaultValueMap and formValues are empty',
      () {
    List<InputConstraint> constraints = [
      InputConstraint(
          defaultValue: 2,
          upper: 3,
          lower: 1,
          types: FieldType.Float,
          name: "somename",
          inputType: InputType.Market)
    ];
    FormBloc bloc = FormBloc(constraints: constraints);
    expect(
        bloc.outFormController,
        emitsInOrder([
          [FormItem(constraint: constraints[0], defaultValue: "2")]
        ]));
  });
  test('gets defaultValueMap if formValues are empty', () {
    List<InputConstraint> constraints = [
      InputConstraint(
          defaultValue: 2,
          upper: 3,
          lower: 1,
          types: FieldType.Integer,
          name: "asset",
          inputType: InputType.Market)
    ];
    FormBloc bloc = FormBloc(constraints: constraints);
    expect(
        bloc.outFormController,
        emitsInOrder([
          [FormItem(constraint: constraints[0], defaultValue: "8")]
        ]));
  });
  test('gets formValue  even if defaultValueMap is set', () {
    List<InputConstraint> constraints = [
      InputConstraint(
          defaultValue: 2,
          upper: 3,
          lower: 1,
          types: FieldType.Integer,
          name: "asset",
          inputType: InputType.Market)
    ];
    FormBloc bloc = FormBloc(constraints: constraints);
    expect(
        bloc.outFormController,
        emitsInOrder([
          [FormItem(constraint: constraints[0], defaultValue: "8")],
          [FormItem(constraint: constraints[0], defaultValue: "7")]
        ]));
    bloc.onSave(InputType.Market, "asset", 7);
    bloc.onSubmit();
  });
}
