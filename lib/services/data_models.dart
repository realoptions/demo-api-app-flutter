import 'package:demo_api_app_flutter/components/CustomTextFields.dart';
enum InputType {Model, Market}
const String MARKET_NAME="market";
class InputConstraint{
  final num lower;
  final num upper;
  final num defaultValue;
  final FieldType types;
  final String name;
  final InputType inputType;

  InputConstraint({
    this.lower,
    this.upper,
    this.types,
    this.name,
    this.defaultValue,
    this.inputType,
  });  
}

class InputConstraints{
  List<InputConstraint> inputConstraints;
  InputConstraints({
    this.inputConstraints
  });

  factory InputConstraints.append(
    InputConstraints firstInputConstraints, 
    InputConstraints secondInputConstraints
  ){
    return InputConstraints(
      inputConstraints: [
        ...firstInputConstraints.inputConstraints, 
        ...secondInputConstraints.inputConstraints
      ]
    );
  }

  factory InputConstraints.fromJson(Map<String, Map<String, dynamic> > parsedJson, String model){
    List<InputConstraint> inputConstraints=[];
    parsedJson.forEach((key, value){
      num lower=value['lower'];
      num upper=value['upper'];
      num defaultValue=(lower+upper)/2.0;
      inputConstraints.add(
        InputConstraint(
          name:key, 
          lower: value['lower'], 
          upper:value['upper'],
          types: value['types']=='float'?FieldType.Float:FieldType.Integer,
          defaultValue:defaultValue,
          inputType: model==MARKET_NAME?InputType.Market:InputType.Model
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

class ModelResult{
  num value;
  num atPoint;
  num iv;
  ModelResult({
    this.value,
    this.atPoint,
    this.iv,
  });
  factory ModelResult.fromJson(Map<String, dynamic> parsedJson){
    return ModelResult(
      value: parsedJson['value'],
      atPoint: parsedJson['atPoint'],
      iv: parsedJson['iv'],
    );
  }
}

class ModelResults{
  List<ModelResult> results;
  ModelResults({
    this.results
  });
  factory ModelResults.fromJson(List<Map<String, dynamic>> parsedJson){
    return ModelResults(results:parsedJson.map((item){
      return ModelResult.fromJson(item);
    }).toList());
  }
}