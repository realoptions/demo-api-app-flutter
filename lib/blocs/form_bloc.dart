import 'package:demo_api_app_flutter/blocs/bloc_provider.dart';
import 'dart:async';
import 'package:demo_api_app_flutter/models/forms.dart';
import 'package:rxdart/rxdart.dart';

const Map<String, String> defaultValueMap = {
  "num_u": "8",
  "asset": "50.0",
  "maturity": "1.0",
};

String valueOtherwiseNull(String value, String defaultValue) {
  if (value == null) {
    return defaultValue;
  } else {
    return value;
  }
}

String getDefaultFormValue(
  Map<String, String> defaultValueMap,
  Map<String, SubmitItems> formValues,
  InputConstraint constraint,
) {
  //formValues take precedence
  SubmitItems formValue = formValues[constraint.name];
  if (formValue != null) {
    return formValue.value.toString();
  }
  return valueOtherwiseNull(
      defaultValueMap[constraint.name], constraint.defaultValue.toString());
}

class FormItem {
  final String defaultValue;
  final InputConstraint constraint;
  FormItem({this.defaultValue, this.constraint});
}

class FormBloc implements BlocBase {
  Map<String, SubmitItems> _formValues = {};
  InputConstraints _inputConstraints;
  StreamController<Iterable<FormItem>> _formController = BehaviorSubject();
  Stream<Iterable<FormItem>> get outFormController => _formController.stream;

  StreamSink get _inFormController => _formController.sink;

  FormBloc(InputConstraints constraints) {
    _inputConstraints = constraints;
    onSubmit();
  }

  void onSave(InputType inputType, String key, num value) {
    _formValues[key] = SubmitItems(inputType: inputType, value: value);
  }

  void onSubmit() {
    var formItems =
        _inputConstraints.inputConstraints.map<FormItem>((constraint) {
      return FormItem(
          defaultValue:
              getDefaultFormValue(defaultValueMap, _formValues, constraint),
          constraint: constraint);
    }); //.toList(); //
    _inFormController.add(formItems);
  }

  Map<String, SubmitItems> getCurrentForm() {
    return _formValues;
  }

  void dispose() {
    _formController.close();
  }
}
