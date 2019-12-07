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
          fieldType: FieldType.Float,
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
          fieldType: FieldType.Integer,
          name: "num_u",
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
          fieldType: FieldType.Integer,
          name: "num_u",
          inputType: InputType.Market)
    ];
    FormBloc bloc = FormBloc(constraints: constraints);
    expect(
        bloc.outFormController,
        emitsInOrder([
          [FormItem(constraint: constraints[0], defaultValue: "8")],
          [FormItem(constraint: constraints[0], defaultValue: "7")]
        ]));
    bloc.onSave(InputType.Market, "num_u", 7);
    bloc.onSubmit();
  });
  test('formValue getter appropriately retrieves', () {
    List<InputConstraint> constraints = [
      InputConstraint(
          defaultValue: 2,
          upper: 3,
          lower: 1,
          fieldType: FieldType.Integer,
          name: "num_u",
          inputType: InputType.Market)
    ];
    FormBloc bloc = FormBloc(constraints: constraints);

    bloc.onSave(InputType.Market, "num_u", 7);
    var formValues = bloc.getCurrentForm();
    expect(formValues,
        {"num_u": SubmitItems(inputType: InputType.Market, value: 7)});
  });
}
