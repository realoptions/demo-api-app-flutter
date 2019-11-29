
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
      atPoint: parsedJson['at_point'],
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