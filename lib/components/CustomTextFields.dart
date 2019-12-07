import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum FieldType { Float, Integer }

class StringUtils {
  String getRegex(FieldType type) {
    switch (type) {
      case FieldType.Float:
        return r"[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)";
      case FieldType.Integer:
        return r"^[1-9]\d*$";
      default:
        return null; //can never get here.  I miss rust...
    }
  }

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
      @required this.type,
      @required this.onSubmit})
      : super(key: key);
  final String hintText;
  final String labelText;
  final String defaultValue;
  final FieldType type;
  final void Function(String, num) onSubmit;
  final StringUtils strUtils = StringUtils();
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
          return null;
        },
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          LengthLimitingTextInputFormatter(12),
          WhitelistingTextInputFormatter(RegExp(strUtils.getRegex(type))),
        ],
        textAlign: TextAlign.right,
        onSaved: (value) => onSubmit(
            this.labelText, strUtils.getValueFromString(this.type, value)));
  }
}
