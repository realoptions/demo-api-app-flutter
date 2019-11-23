import 'package:flutter/material.dart';
import 'package:demo_api_app_flutter/components/CustomPadding.dart';
import 'package:demo_api_app_flutter/components/CustomTextFields.dart';
import 'package:demo_api_app_flutter/services/data_models.dart';
import 'package:demo_api_app_flutter/services/api_consume.dart';

Widget getField(InputConstraint constraint){
  switch(constraint.types){
    case FieldType.Integer:
      return PaddingForm(
        child:IntegerTextField(
          labelText: constraint.name, 
          defaultValue: constraint.defaultValue.toString(),
        )
      );
      break;
    case FieldType.Float:
      return PaddingForm(
        child:FloatTextField(
          labelText: constraint.name, 
          defaultValue: constraint.defaultValue.toString(),
        )
      );
      break;
    default:
      return Text("something went wrong");//should never get here
      break;
  }
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

  @override
  Widget build(BuildContext context) {
    List<Widget> formFields=widget.constraints.inputConstraints.map(getField).toList();
    formFields.add(
      PaddingForm(
        child: RaisedButton(
          onPressed: () {
            // Validate returns true if the form is valid, or false
            // otherwise.
            print(_formKey.currentState.toString());
            if (_formKey.currentState.validate()) {
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