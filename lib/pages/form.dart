import 'package:flutter/material.dart';
import 'package:demo_api_app_flutter/components/CustomPadding.dart';
import 'package:demo_api_app_flutter/components/CustomTextFields.dart';
import 'package:demo_api_app_flutter/storage/convert_constraint.dart';

Widget getField(InputConstraint constraint){
  switch(constraint.types){
    case FieldType.Integer:
      return PaddingForm(child:IntegerTextField(labelText: constraint.name));
      break;
    case FieldType.Float:
      return PaddingForm(child:FloatTextField(labelText: constraint.name));
      break;
    default:
      return Text("something went wrong");//should never get here
      break;
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
    //List<Widget> formFields=widget.constraints.inputConstraints.map(getField).toList();
    // Build a Form widget using the _formKey created above.
    List<Widget> formFields=widget.constraints.inputConstraints.map(getField).toList();
    formFields.add(
      FlatButton(
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
    ));
    return Form(
      autovalidate: true,
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: formFields
      )
    );
  }
}