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

Function getField(Function onSubmit){
  return (InputConstraint constraint){
    String defaultValue=defaultValueMap[constraint.name]!=null?defaultValueMap[constraint.name]:constraint.defaultValue.toString();
    return PaddingForm(
      child:NumberTextField(
        labelText: constraint.name, 
        defaultValue: defaultValue,
        type: constraint.types,
        onSubmit: onSubmit,
      )
    );
  };
}



class InputForm extends StatelessWidget {
  const InputForm({
    Key key,
    this.model,
    this.apiKey
  }) : super(key: key);
  final String model;
  final String apiKey;
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
              constraints:snapshot.data
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
    @required this.constraints
  });
  final InputConstraints constraints;
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
  Map<String, num>_mapOfValues={};

  onSubmit(String name, num value){
    setState((){
      _mapOfValues[name]=value;
    });
  }

  @override
  Widget build(BuildContext context) {
    //wow this works!
    //TODO! hoist this up to main app
    print(_mapOfValues);
    List<Widget> formFields=widget.constraints.inputConstraints.map<Widget>(getField(onSubmit)).toList();
    formFields.add(
      PaddingForm(
        child: RaisedButton(
          onPressed: () {
            // Validate returns true if the form is valid, or false
            // otherwise.
            print(_formKey.currentState.toString());
            if (_formKey.currentState.validate()) {
              _formKey.currentState.save();//what does this do???
              // If the form is valid, display a Snackbar.
              Scaffold.of(context)
                  .showSnackBar(SnackBar(content: Text('Processing Data')));
                  _formKey.currentState.save();
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