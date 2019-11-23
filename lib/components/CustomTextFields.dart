import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class IntegerTextField extends StatelessWidget{
  const IntegerTextField({
    Key key,
    this.hintText,
    this.labelText,
    this.defaultValue
  }) : super(key: key);
  final String hintText;
  final String labelText;
  final String defaultValue;
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
          WhitelistingTextInputFormatter(RegExp(r"(?<=\s|^)\d+(?=\s|$)")),
      ],
      textAlign: TextAlign.right
      //controller: ,
    );
  }
}

class FloatTextField extends StatelessWidget{
  const FloatTextField({
    Key key,
    this.hintText,
    this.labelText,
    this.defaultValue,
  }) : super(key: key);
  final String hintText;
  final String labelText;
  final String defaultValue;
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
          WhitelistingTextInputFormatter(RegExp(r"[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)")),
      ],
      textAlign: TextAlign.right
      //controller: ,
    );
  }
}