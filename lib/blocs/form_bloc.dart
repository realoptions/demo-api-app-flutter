import 'package:demo_api_app_flutter/blocs/bloc_provider.dart';
import 'dart:async';
import 'package:demo_api_app_flutter/models/forms.dart';
import 'package:rxdart/rxdart.dart';
import 'package:quiver/core.dart' show hash2;

const Map<String, String> defaultValueMap = {
  "num_u": "8",
  "asset": "50.0",
  "maturity": "1.0",
};

class FormItem {
  final String defaultValue;
  final InputConstraint constraint;
  FormItem({this.defaultValue, this.constraint});
  @override
  bool operator ==(other) {
    if (other is! FormItem) {
      return false;
    }

    if (defaultValue != other.defaultValue) {
      return false;
    }
    if (constraint != other.constraint) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => hash2(defaultValue, constraint);
}

class FormBloc implements BlocBase {
  Map<String, SubmitItems> _formValues = {};
  final List<InputConstraint> constraints;
  final StreamController<Iterable<FormItem>> _formController =
      BehaviorSubject();
  Stream<Iterable<FormItem>> get outFormController => _formController.stream;

  StreamSink get _inFormController => _formController.sink;

  FormBloc({this.constraints}) {
    onSubmit();
  }
  static String _valueOtherwiseNull(String value, String defaultValue) {
    if (value == null) {
      return defaultValue;
    } else {
      return value;
    }
  }

  static String _getDefaultFormValue(
    Map<String, String> defaultValueMap,
    Map<String, SubmitItems> formValues, //can be empty
    InputConstraint constraint, //can't be null
  ) {
    //formValues take precedence
    SubmitItems formValue = formValues[constraint.name];
    if (formValue != null) {
      return formValue.value.toString();
    }
    return _valueOtherwiseNull(
        defaultValueMap[constraint.name], constraint.defaultValue.toString());
  }

  void onSave(InputType inputType, String key, num value) {
    _formValues[key] = SubmitItems(inputType: inputType, value: value);
  }

  void onSubmit() {
    var formItems = constraints.map<FormItem>((constraint) {
      return FormItem(
          defaultValue:
              _getDefaultFormValue(defaultValueMap, _formValues, constraint),
          constraint: constraint);
    }).toList();
    _inFormController.add(formItems);
  }

  Map<String, SubmitItems> getCurrentForm() {
    return _formValues;
  }

  void dispose() {
    _formController.close();
  }
}
