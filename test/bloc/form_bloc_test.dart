import 'package:realoptions/components/CustomTextFields.dart';
import 'package:realoptions/models/forms.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/blocs/form_bloc.dart';

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
          inputType: InputType.Market,
          description: "hello")
    ];
    FormBloc bloc = FormBloc(constraints: constraints);
    expect(
        bloc.outFormController,
        emitsInOrder([
          [FormItem(constraint: constraints[0], valueAtLastSubmit: "2.00")]
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
          inputType: InputType.Market,
          description: "hello")
    ];
    FormBloc bloc = FormBloc(constraints: constraints);
    expect(
        bloc.outFormController,
        emitsInOrder([
          [FormItem(constraint: constraints[0], valueAtLastSubmit: "2")]
        ]));
  });
  test('gets formValue even if defaultValueMap is set', () {
    List<InputConstraint> constraints = [
      InputConstraint(
          defaultValue: 2,
          upper: 3,
          lower: 1,
          fieldType: FieldType.Integer,
          name: "num_u",
          inputType: InputType.Market,
          description: "hello")
    ];
    FormBloc bloc = FormBloc(constraints: constraints);
    expect(
        bloc.outFormController,
        emitsInOrder([
          [FormItem(constraint: constraints[0], valueAtLastSubmit: "2")],
          [FormItem(constraint: constraints[0], valueAtLastSubmit: "7")]
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
          inputType: InputType.Market,
          description: "hello")
    ];
    FormBloc bloc = FormBloc(constraints: constraints);

    bloc.onSave(InputType.Market, "num_u", 7);
    var formValues = bloc.getCurrentForm();
    expect(formValues,
        {"num_u": SubmitItems(inputType: InputType.Market, value: 7)});
  });
}
