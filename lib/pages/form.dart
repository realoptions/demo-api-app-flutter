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

Function getField(Function onSubmit){
  return (InputConstraint constraint){
    String defaultValue=defaultValueMap[constraint.name]!=null?defaultValueMap[constraint.name]:constraint.defaultValue.toString();
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
    this.model,
    this.apiKey,
    this.onSubmit,
  }) : super(key: key);
  final String model;
  final String apiKey;
  final Function onSubmit;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<InputConstraints>(
      future: fetchConstraints(this.model, this.apiKey),
      builder: (BuildContext context, AsyncSnapshot<InputConstraints> snapshot){
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
              apiKey:this.apiKey
            );
          default:
            return Center(child: CircularProgressIndicator()); 
        }

      }
    );
  }
}


class SpecToForm extends StatefulWidget {
  SpecToForm({
    @required this.constraints,
    @required this.model,
    @required this.onSubmit,
    @required this.apiKey
  });
  final InputConstraints constraints;
  final String model;
  final Function onSubmit;
  final String apiKey;
  @override
  SpecToFormState createState()=>SpecToFormState();
}


// Define a corresponding State class.
// This class holds data related to the form.
class SpecToFormState extends State<SpecToForm> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a `GlobalKey<FormState>`,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();
  Map<String, SubmitItems>_mapOfValues={};

  onSave(inputType){
    return (String name, num value){
      _mapOfValues[name]=SubmitItems(
        inputType:inputType, 
        value:value
      );
    };//);
   // };
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> formFields=widget.constraints.inputConstraints.map<Widget>(getField(onSave)).toList();
    formFields.add(
      PaddingForm(
        child: RaisedButton(
          onPressed: () {
            // Validate returns true if the form is valid, or false
            // otherwise.
            if (_formKey.currentState.validate()) {
              _formKey.currentState.save();//this calls "onSubmit", which may not be that useful
              // If the form is valid, display a Snackbar.

              fetchOptionPricesAndDensity(widget.model, widget.apiKey, _mapOfValues).then(widget.onSubmit);
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