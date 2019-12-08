import 'package:realoptions/blocs/constraints_bloc.dart';
import 'package:realoptions/blocs/options_bloc.dart';
import 'package:realoptions/blocs/select_page_bloc.dart';
import 'package:realoptions/models/pages.dart';
import 'package:flutter/material.dart';
import 'package:realoptions/components/CustomPadding.dart';
import 'package:realoptions/components/CustomTextFields.dart';
import 'package:realoptions/models/forms.dart';
import 'package:realoptions/blocs/form_bloc.dart';
import 'package:realoptions/blocs/bloc_provider.dart';
import 'package:realoptions/blocs/density_bloc.dart';
import 'package:realoptions/models/progress.dart';

Widget getField(
    Function onSubmit, String defaultValue, InputConstraint constraint) {
  return PaddingForm(
      child: NumberTextField(
    labelText: constraint.name,
    defaultValue: defaultValue,
    type: constraint.fieldType,
    onSubmit: (String key, num value) =>
        onSubmit(constraint.inputType, key, value),
  ));
}

class InputForm extends StatelessWidget {
  const InputForm({Key key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    ConstraintsBloc bloc = BlocProvider.of<ConstraintsBloc>(context);
    return StreamBuilder<StreamProgress>(
        stream: bloc.outConstraintsProgress,
        builder: (buildContext, snapshot) {
          switch (snapshot.data) {
            case StreamProgress.Busy:
              return Center(child: CircularProgressIndicator());
            case StreamProgress.DataRetrieved:
              return StreamBuilder<List<InputConstraint>>(
                  stream: bloc.outConstraintsController,
                  builder: (buildContext, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text(snapshot.error.toString()));
                    }
                    if (snapshot.data == null) {
                      return Center(child: CircularProgressIndicator());
                    }
                    return BlocProvider<FormBloc>(
                        bloc: FormBloc(constraints: snapshot.data),
                        child: SpecToForm());
                  });
            default: //should never get here
              return Center(child: CircularProgressIndicator());
          }
        });
  }
}

class SpecToForm extends StatelessWidget {
  const SpecToForm({Key key}) : super(key: key);
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
              densityBloc.getDensity(submittedBody).then((_) {
                pageBloc.setBadge(DENSITY_PAGE);
              });
              optionsBloc.getOptionPrices(submittedBody).then((_) {
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
