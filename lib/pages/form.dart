import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realoptions/blocs/density/density_bloc.dart';
import 'package:realoptions/blocs/density/density_state.dart';
import 'package:realoptions/blocs/options/options_bloc.dart';
import 'package:realoptions/blocs/options/options_state.dart';
import 'package:flutter/material.dart';
import 'package:realoptions/blocs/select_model/select_model_bloc.dart';
import 'package:realoptions/components/CustomPadding.dart';
import 'package:realoptions/components/CustomTextFields.dart';
import 'package:realoptions/models/forms.dart';
import 'package:realoptions/blocs/form/form_bloc.dart';
import 'package:realoptions/models/models.dart';

Widget getField(BuildContext context, String valueAtLastSubmit,
    InputConstraint constraint) {
  final ThemeData themeData = Theme.of(context);
  return PaddingForm(
      child: Row(children: [
    Expanded(
        child: NumberTextField(
      labelText: constraint.name,
      defaultValue: valueAtLastSubmit,
      type: constraint.fieldType,
      lowValue: constraint.lower,
      highValue: constraint.upper,
      onSaved: (String key, num value) =>
          context.read<FormBloc>().onSave(constraint.inputType, key, value),
    )),
    IconButton(
      color: themeData.primaryColor,
      icon: Icon(Icons.help),
      onPressed: () {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(content: Text(constraint.description));
            });
      },
    )
  ]));
}

class InputForm extends StatelessWidget {
  const InputForm({Key key}) : super(key: key);
  static final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext _) {
    return BlocBuilder<FormBloc, Iterable<FormItem>>(builder: (context, data) {
      List<Widget> formFields = data.map<Widget>((FormItem formItem) {
        return getField(
            context, formItem.valueAtLastSubmit, formItem.constraint);
      }).toList();
      formFields.add(PaddingForm(child: FormButton(formKey: _formKey)));
      return SingleChildScrollView(
          child: Form(
              autovalidateMode: AutovalidateMode.always,
              key: _formKey,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: formFields)),
          key: PageStorageKey("Form"));
    });
  }
}

class FormButton extends StatelessWidget {
  FormButton({@required this.formKey});
  final GlobalKey<FormState> formKey;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ButtonStyle style = ElevatedButton.styleFrom(
      textStyle: TextStyle(
        color: Colors.black,
      ),
      onPrimary: Colors.black,
      primary: theme.accentColor,
    );
    return BlocBuilder<DensityBloc, DensityState>(
        builder: (context, densityData) {
      return BlocBuilder<OptionsBloc, OptionsState>(
          builder: (context, optionsData) {
        if (densityData is IsDensityFetching &&
            optionsData is IsOptionsFetching) {
          return CircularProgressIndicator();
        }
        return BlocBuilder<SelectModelBloc, Model>(builder: (context, model) {
          return ElevatedButton(
            style: style,
            onPressed: () {
              // Validate returns true if the form is valid, or false
              // otherwise.
              if (formKey.currentState.validate()) {
                formKey.currentState.save();
                final submittedBody = context.read<FormBloc>().getCurrentForm();
                final SubmitBody body = SubmitBody(formBody: submittedBody);
                final jsonBody = body.convertSubmission();
                context.read<DensityBloc>().getDensity(model.value, jsonBody);
                context.read<OptionsBloc>().getOptions(model.value, jsonBody);
              }
            },
            child: Text('Submit'),
          );
        });
      });
    });
  }
}
