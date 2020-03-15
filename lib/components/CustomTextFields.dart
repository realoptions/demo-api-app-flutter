import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum FieldType { Float, Integer }

class StringUtils {
  num getValueFromString(FieldType type, String value) {
    switch (type) {
      case FieldType.Float:
        return double.parse(value);
      case FieldType.Integer:
        return int.parse(value);
      default:
        return null; //can never get here.  I miss rust...
    }
  }
}

class NumberTextField extends StatelessWidget {
  NumberTextField(
      {Key key,
      this.hintText,
      this.labelText,
      this.defaultValue,
      this.lowValue = double.negativeInfinity,
      this.highValue = double.infinity,
      @required this.type,
      @required this.onSubmit})
      : super(key: key);
  final String hintText;
  final String labelText;
  final String defaultValue;
  final FieldType type;
  final void Function(String, num) onSubmit;
  final StringUtils strUtils = StringUtils();
  final num lowValue;
  final num highValue;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
        initialValue: this.defaultValue,
        decoration: InputDecoration(
          hintText: this.hintText,
          labelText: this.labelText,
        ),
        validator: (value) {
          if (value.isEmpty) {
            return 'Please enter some text';
          }
          num currentValue;
          try {
            currentValue = strUtils.getValueFromString(type, value);
          } catch (_err) {
            return 'Not a valid number!';
          }

          if (currentValue < lowValue || currentValue > highValue) {
            return 'Number must be between ' +
                lowValue.toString() +
                ' and ' +
                highValue.toString();
          }
          return null;
        },
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          LengthLimitingTextInputFormatter(12),
        ],
        textAlign: TextAlign.right,
        onSaved: (value) => onSubmit(
            this.labelText, strUtils.getValueFromString(this.type, value)));
  }
}
