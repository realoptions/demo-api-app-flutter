enum FieldType{Float, Integer}

class InputConstraint{
  final num lower;
  final num upper;
  final FieldType types;
  final String name;

  InputConstraint({
    this.lower,
    this.upper,
    this.types,
    this.name
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
      inputConstraints.add(
        InputConstraint(
          name:key, 
          lower: value['lower'], 
          upper:value['upper'],
          types: value['types']=='float'?FieldType.Float:FieldType.Integer
        )
      );
    });
    return InputConstraints(inputConstraints:inputConstraints);
  }
}

