import 'package:realoptions/models/forms.dart';
import 'package:quiver/core.dart' show hash2;
import 'package:meta/meta.dart';
import 'package:realoptions/components/CustomTextFields.dart';
import 'package:bloc/bloc.dart';

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

class FormBloc extends Cubit<Iterable<FormItem>> {
  final List<InputConstraint> constraints;
  Map<String, SubmitItems> _formValues = {};
  FormBloc({@required this.constraints}) : super(_onSubmit({}, constraints));

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

  static List<FormItem> _onSubmit(
      Map<String, SubmitItems> formValues, List<InputConstraint> constraints) {
    return constraints.map<FormItem>((constraint) {
      return FormItem(
          constraint: constraint,
          valueAtLastSubmit: _getValueAtLastSubmit(formValues, constraint));
    }).toList();
  }

  void onSave(InputType inputType, String key, num value) {
    _formValues[key] = SubmitItems(inputType: inputType, value: value);
  }

  Map<String, SubmitItems> getCurrentForm() {
    return _formValues;
  }
}
