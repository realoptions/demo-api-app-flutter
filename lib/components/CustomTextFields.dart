import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum FieldType{Float, Integer}
String getRegex(FieldType field){
  switch(field){
    case FieldType.Float:
      return r"[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)";
    case FieldType.Integer:
      return r"(?<=\s|^)\d+(?=\s|$)";
    default:
      return null;//can never get here.  I miss rust...
  }
}
class NumberTextField extends StatelessWidget{
  const NumberTextField({
    Key key,
    this.hintText,
    this.labelText,
    this.defaultValue,
    this.type
  }) : super(key: key);
  final String hintText;
  final String labelText;
  final String defaultValue;
  final FieldType type;
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
          WhitelistingTextInputFormatter(RegExp(getRegex(type))),
      ],
      textAlign: TextAlign.right
      //controller: ,
    );
  }
}