import 'package:demo_api_app_flutter/blocs/constraints_bloc.dart';
import 'package:demo_api_app_flutter/blocs/options_bloc.dart';
import 'package:demo_api_app_flutter/blocs/select_page_bloc.dart';
import 'package:demo_api_app_flutter/models/pages.dart';
import 'package:flutter/material.dart';
import 'package:demo_api_app_flutter/components/CustomPadding.dart';
import 'package:demo_api_app_flutter/components/CustomTextFields.dart';
import 'package:demo_api_app_flutter/models/forms.dart';
import 'package:demo_api_app_flutter/blocs/form_bloc.dart';
import 'package:demo_api_app_flutter/blocs/bloc_provider.dart';
import 'package:demo_api_app_flutter/blocs/density_bloc.dart';

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
  const InputForm({Key key, this.model, this.apiKey}) : super(key: key);
  final String model;
  final String apiKey;
  @override
  Widget build(BuildContext context) {
    ConstraintsBloc bloc = BlocProvider.of<ConstraintsBloc>(context);
    return StreamBuilder<List<InputConstraint>>(
        stream: bloc.outConstraintsController,
        builder: (buildContext, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return Center(child: CircularProgressIndicator());
            case ConnectionState.active:
            case ConnectionState.done:
              if (snapshot.hasError) return Text('Error: ${snapshot.error}');
              if (snapshot.data == null) {
                return Center(child: CircularProgressIndicator());
              }
              return BlocProvider<FormBloc>(
                  bloc: FormBloc(snapshot.data),
                  child: SpecToForm(model: model, apiKey: apiKey));
            default: //can never get here
              return Center(child: CircularProgressIndicator());
          }
        });
  }
}

class SpecToForm extends StatelessWidget {
  const SpecToForm({Key key, this.model, this.apiKey}) : super(key: key);
  final String model;
  final String apiKey;
  static final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    FormBloc bloc = BlocProvider.of<FormBloc>(context);
    DensityBloc densityBloc = BlocProvider.of<DensityBloc>(context);
    OptionsBloc optionsBloc = BlocProvider.of<OptionsBloc>(context);
    SelectPageBloc pageBloc = BlocProvider.of<SelectPageBloc>(context);
    return StreamBuilder<Iterable<FormItem>>(
      stream: bloc.outFormController,
      initialData: [],
      builder: (buildContext, snapshot) {
        List<Widget> formFields =
            snapshot.data.map<Widget>((FormItem formItem) {
          return getField(
              bloc.onSave, formItem.defaultValue, formItem.constraint);
        }).toList();
        formFields.add(PaddingForm(
            child: RaisedButton(
          onPressed: () {
            // Validate returns true if the form is valid, or false
            // otherwise.
            if (_formKey.currentState.validate()) {
              _formKey.currentState.save();
              bloc.onSubmit();
              //is this the optimal way??
              var submittedBody = bloc.getCurrentForm();
              densityBloc.getDensity(model, apiKey, submittedBody).then((_) {
                pageBloc.setBadge(DENSITY_PAGE);
              });
              optionsBloc
                  .getOptionPrices(model, apiKey, submittedBody)
                  .then((_) {
                pageBloc.setBadge(OPTIONS_PAGE);
              });
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
