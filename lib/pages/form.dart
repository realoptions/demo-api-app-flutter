import 'package:demo_api_app_flutter/blocs/constraints_bloc.dart';
import 'package:flutter/material.dart';
import 'package:demo_api_app_flutter/components/CustomPadding.dart';
import 'package:demo_api_app_flutter/components/CustomTextFields.dart';
//import 'package:demo_api_app_flutter/models/response.dart' as response_model;
import 'package:demo_api_app_flutter/models/forms.dart';
import 'package:demo_api_app_flutter/blocs/form_bloc.dart';
import 'package:demo_api_app_flutter/blocs/bloc_provider.dart';

//typedef SubmitType = void Function(
//    Future<Map<String, response_model.ModelResults>> values);
//typedef FormSave = Function(String a, num b) Function(InputType inputType);

Widget getField(
    Function onSubmit, String defaultValue, InputConstraint constraint) {
  return PaddingForm(
      child: NumberTextField(
    labelText: constraint.name,
    defaultValue: defaultValue,
    type: constraint.types,
    onSubmit: (String key, num value) =>
        onSubmit(constraint.inputType, key, value),
  ));
}

class InputForm extends StatelessWidget {
  const InputForm({
    Key key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    ConstraintsBloc bloc = BlocProvider.of<ConstraintsBloc>(context);

    return StreamBuilder(
        stream: bloc.outConstraintsController,
        builder: (buildContext, snapshot) {
          print("in stream builder for form");
          print(snapshot.connectionState);
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return Center(child: CircularProgressIndicator());
            case ConnectionState.active:
            case ConnectionState.done:
              if (snapshot.hasError) return Text('Error: ${snapshot.error}');
              return BlocProvider<FormBloc>(
                  bloc: FormBloc(snapshot.data), child: SpecToForm());
            default: //can never get here
              return Center(child: CircularProgressIndicator());
          }
        });
  }
}

class SpecToForm extends StatelessWidget {
  const SpecToForm({
    Key key,
  }) : super(key: key);
  static final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    FormBloc bloc = BlocProvider.of<FormBloc>(context);
    return StreamBuilder(
      stream: bloc.outFormController,
      builder: (buildContext, snapshot) {
        List<Widget> formFields = snapshot.data.map((formItem) {
          return getField(
              bloc.onSave, formItem.defaultValue, formItem.constraint);
        });
        formFields.add(PaddingForm(
            child: RaisedButton(
          onPressed: () {
            // Validate returns true if the form is valid, or false
            // otherwise.
            if (_formKey.currentState.validate()) {
              _formKey.currentState.save();
              bloc.onSubmit(snapshot.data);
              //this.onSubmit(fetchOptionPricesAndDensity(
              //   this.model, this.apiKey, this.formValues));
            }
          },
          child: Text('Submit'),
        )));
        return SingleChildScrollView(
            child: Form(
                autovalidate: true,
                key: _formKey,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: formFields)),
            key: PageStorageKey("Form"));
      },
    );
  }
}
