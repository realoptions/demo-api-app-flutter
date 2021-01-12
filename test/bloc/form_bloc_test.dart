import 'package:realoptions/components/CustomTextFields.dart';
import 'package:realoptions/models/forms.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/blocs/form/form_bloc.dart';
import 'package:bloc_test/bloc_test.dart';

void main() {
  test('correct initial state', () async {
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
    expect(bloc.state,
        [FormItem(constraint: constraints[0], valueAtLastSubmit: "2.00")]);
  });
  test('formValues is changed after onSave', () {
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
    final initFormValues = bloc.getCurrentForm();
    expect(initFormValues, {});
    bloc.onSave(InputType.Market, "num_u", 7);
    final formValues = bloc.getCurrentForm();
    expect(formValues,
        {"num_u": SubmitItems(inputType: InputType.Market, value: 7)});
  });
  test('formValues is changed after onSave is called twice', () {
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
    bloc.onSave(InputType.Market, "num_u", 6);
    final initFormValues = bloc.getCurrentForm();
    expect(initFormValues,
        {"num_u": SubmitItems(inputType: InputType.Market, value: 6)});
    bloc.onSave(InputType.Market, "num_u", 7);
    final formValues = bloc.getCurrentForm();
    expect(formValues,
        {"num_u": SubmitItems(inputType: InputType.Market, value: 7)});
  });
}
