import 'package:demo_api_app_flutter/components/CustomTextFields.dart';

class InputConstraint{
  final num lower;
  final num upper;
  final num defaultValue;
  final FieldType types;
  final String name;

  InputConstraint({
    this.lower,
    this.upper,
    this.types,
    this.name,
    this.defaultValue
  });  
}

class InputConstraints{
  List<InputConstraint> inputConstraints;
  InputConstraints({
    this.inputConstraints
  });

  factory InputConstraints.fromJson(Map<String, Map<String, dynamic> > parsedJson){
    List<InputConstraint> inputConstraints=[];
    parsedJson.forEach((key, value){
      num lower=value['lower'];
      num upper=value['upper'];
      num defaultValue=(lower+upper)/2.0;
      print(value['types']);
      inputConstraints.add(
        InputConstraint(
          name:key, 
          lower: value['lower'], 
          upper:value['upper'],
          types: value['types']=='float'?FieldType.Float:FieldType.Integer,
          defaultValue:defaultValue
        )
      );
    });
    return InputConstraints(inputConstraints:inputConstraints);
  }
}

class ErrorMessage{
  String message;
  ErrorMessage({
    this.message
  });
  factory ErrorMessage.fromJson(Map<String, dynamic> parsedJson){
    return ErrorMessage(message:parsedJson['message']);
  }
}