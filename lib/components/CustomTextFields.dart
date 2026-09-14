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
    }
  }

  String getStringFromValue(FieldType fieldType, num val) {
    switch (fieldType) {
      case FieldType.Float:
        return val.toStringAsFixed(2);
      case FieldType.Integer:
        return val.toStringAsFixed(0);
    }
  }
}

class NumberTextField extends StatelessWidget {
  NumberTextField(
      {super.key,
      this.hintText,
      this.labelText,
      this.defaultValue,
      this.lowValue = double.negativeInfinity,
      this.highValue = double.infinity,
      required this.type,
      required this.onSaved});
  final String? hintText;
  final String? labelText;
  final String? defaultValue;
  final FieldType type;
  final void Function(String, num) onSaved;
  final StringUtils strUtils = StringUtils();
  final num lowValue;
  final num highValue;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
        initialValue: defaultValue,
        decoration: InputDecoration(
          hintText: hintText,
          labelText: labelText,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter some text';
          }
          num currentValue;
          try {
            currentValue = strUtils.getValueFromString(type, value);
          } catch (_) {
            return 'Not a valid number!';
          }

          if (currentValue < lowValue || currentValue > highValue) {
            return 'Number must be between $lowValue and $highValue';
          }
          return null;
        },
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          LengthLimitingTextInputFormatter(12),
        ],
        textAlign: TextAlign.right,
        onSaved: (value) => onSaved(
            labelText ?? '', strUtils.getValueFromString(type, value ?? '')));
  }
}
