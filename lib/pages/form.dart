import 'package:flutter/material.dart';
import 'package:demo_api_app_flutter/components/CustomPadding.dart';
import 'package:demo_api_app_flutter/components/CustomTextFields.dart';
import 'package:demo_api_app_flutter/services/data_models.dart';
import 'package:demo_api_app_flutter/services/api_consume.dart';

const Map<String, String> defaultValueMap={
  "num_u":"8",
  "asset":"50.0",
  "maturity":"1.0",
};

class SubmitItems{
  final num value;
  final InputType inputType;
  const SubmitItems({
    this.value,
    this.inputType
  });
}
String valueOtherwiseNull(String value, String defaultValue){
  if(value==null){
    return defaultValue;
  }
  else{
    return value;
  }
}
String getDefaultFormValue(
  Map<String, String> defaultValueMap,
  Map<String, SubmitItems> formValues,
  InputConstraint constraint,
){
  //formValues take precedence
  SubmitItems formValue=formValues[constraint.name];
  if(formValue!=null){
    return formValue.value.toString();
  }
  return valueOtherwiseNull(defaultValueMap[constraint.name], constraint.defaultValue.toString());
}

Function getField(Function onSubmit, Map<String, SubmitItems> formValues){
  return (InputConstraint constraint){
    String defaultValue=getDefaultFormValue(
      defaultValueMap, formValues, constraint
    );
    return PaddingForm(
      child:NumberTextField(
        labelText: constraint.name, 
        defaultValue: defaultValue,
        type: constraint.types,
        onSubmit: onSubmit(constraint.inputType),
      )
    );
  };
}



class InputForm extends StatelessWidget {
  const InputForm({
    Key key,
    @required this.model,
    @required this.apiKey,
    @required this.onSubmit,
    @required this.snapshot,
    @required this.formValues,
    @required this.onSave,
  }) : super(key: key);
  final String model;
  final String apiKey;
  final Function onSubmit;
  final AsyncSnapshot snapshot;
  final Map<String, SubmitItems> formValues;
  final Function onSave;
  @override
  Widget build(BuildContext context) {
    switch (snapshot.connectionState) {
      case ConnectionState.none:
      case ConnectionState.active:
      case ConnectionState.waiting:
        return Center(child: CircularProgressIndicator());
      case ConnectionState.done:
        if (snapshot.hasError)
          return Text('Error: ${snapshot.error}');
        return SpecToForm(
          constraints:snapshot.data,
          model:this.model,
          onSubmit:this.onSubmit,
          apiKey:this.apiKey,
          formValues: this.formValues,
          onSave: this.onSave
        );
      default:
        return Center(child: CircularProgressIndicator()); 
    }
  }
}

/*
class SpecToForm extends StatefulWidget {
  SpecToForm({
    @required this.constraints,
    @required this.model,
    @required this.onSubmit,
    @required this.apiKey,
    @required this.onSave,
    @required this.formValues
  });
  final InputConstraints constraints;
  final String model;
  final Function onSubmit;
  final String apiKey;
  final Function onSave;
  final Map formValues;
  @override
  SpecToFormState createState()=>SpecToFormState();
}*/


// Define a corresponding State class.
// This class holds data related to the form.
class SpecToForm extends StatelessWidget {
  const SpecToForm({
    Key key,
    @required this.constraints,
    @required this.model,
    @required this.apiKey,
    @required this.onSubmit,
    @required this.formValues,
    @required this.onSave,
  }) : super(key: key);
  final InputConstraints constraints;
  final String model;
  final Function onSubmit;
  final String apiKey;
  final Function onSave;
  final Map<String, SubmitItems> formValues;
  static final _formKey = GlobalKey<FormState>();
 
  @override
  Widget build(BuildContext context) {
    List<Widget> formFields=this.constraints.inputConstraints.map<Widget>(
      getField(this.onSave, this.formValues)
    ).toList();
    formFields.add(
      PaddingForm(
        child: RaisedButton(
          onPressed: () {
            // Validate returns true if the form is valid, or false
            // otherwise.
            if (_formKey.currentState.validate()) {
              _formKey.currentState.save();
              fetchOptionPricesAndDensity(
                this.model, 
                this.apiKey, 
                this.formValues
              ).then(this.onSubmit);
            }
          },
          child: Text('Submit'),
        )
      )
    );
    return SingleChildScrollView(
      child:Form(
        autovalidate: true,
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: formFields
        )
      )
    );
  }
}