import 'package:realoptions/blocs/bloc_provider.dart';
import 'dart:async';
import 'package:realoptions/models/forms.dart';
import 'package:rxdart/rxdart.dart';
import 'package:quiver/core.dart' show hash2;
import 'package:meta/meta.dart';
import 'package:realoptions/components/CustomTextFields.dart';

class FormItem {
  final String valueAtLastSubmit;
  final InputConstraint constraint;
  FormItem({this.valueAtLastSubmit, this.constraint});
  @override
  bool operator ==(other) {
    if (other is! FormItem) {
      return false;
    }

    if (valueAtLastSubmit != other.valueAtLastSubmit) {
      return false;
    }
    if (constraint != other.constraint) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => hash2(valueAtLastSubmit, constraint);
}

final StringUtils stringUtils = StringUtils();

class FormBloc implements BlocBase {
  Map<String, SubmitItems> _formValues = {};
  final List<InputConstraint> constraints;
  final StreamController<Iterable<FormItem>> _formController =
      BehaviorSubject();

  Stream<Iterable<FormItem>> get outFormController => _formController.stream;

  StreamSink get _inFormController => _formController.sink;

  FormBloc({@required this.constraints}) {
    onSubmit();
  }

  static String _getValueAtLastSubmit(
    Map<String, SubmitItems> formValues, //can be empty
    InputConstraint constraint, //can't be null
  ) {
    //formValues take precedence
    SubmitItems formValue = formValues[constraint.name];
    if (formValue != null) {
      return formValue.value.toString();
    }
    return stringUtils.getStringFromValue(
        constraint.fieldType, constraint.defaultValue);
  }

  void onSave(InputType inputType, String key, num value) {
    _formValues[key] = SubmitItems(inputType: inputType, value: value);
  }

  void onSubmit() {
    var formItems = constraints.map<FormItem>((constraint) {
      return FormItem(
          constraint: constraint,
          valueAtLastSubmit: _getValueAtLastSubmit(_formValues, constraint));
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
