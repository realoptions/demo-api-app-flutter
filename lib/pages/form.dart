import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realoptions/blocs/density/density_bloc.dart';
import 'package:realoptions/blocs/density/density_state.dart';
import 'package:realoptions/blocs/options/options_bloc.dart';
import 'package:realoptions/blocs/options/options_state.dart';
import 'package:flutter/material.dart';
import 'package:realoptions/components/CustomPadding.dart';
import 'package:realoptions/components/CustomTextFields.dart';
import 'package:realoptions/models/forms.dart';
import 'package:realoptions/blocs/form/form_bloc.dart';

Widget getField(BuildContext context, Function onSubmit,
    String valueAtLastSubmit, InputConstraint constraint) {
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
      onSubmit: (String key, num value) =>
          onSubmit(constraint.inputType, key, value),
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
  Widget build(BuildContext context) {
    return BlocBuilder<FormBloc, Iterable<FormItem>>(builder: (context, data) {
      final onSave = context.read<FormBloc>().onSave;
      List<Widget> formFields = data.map<Widget>((FormItem formItem) {
        return getField(
            context, onSave, formItem.valueAtLastSubmit, formItem.constraint);
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
    final formBloc = context.read<FormBloc>();
    final optionsBloc = context.read<OptionsBloc>();
    final densityBloc = context.read<DensityBloc>();
    return BlocBuilder<DensityBloc, DensityState>(
        builder: (context, densityData) {
      return BlocBuilder<OptionsBloc, OptionsState>(
          builder: (context, optionsData) {
        if (densityData is IsDensityFetching &&
            optionsData is IsOptionsFetching) {
          return CircularProgressIndicator();
        }
        return RaisedButton(
          onPressed: () {
            // Validate returns true if the form is valid, or false
            // otherwise.
            if (formKey.currentState.validate()) {
              formKey.currentState.save();
              var submittedBody = formBloc.getCurrentForm();
              densityBloc.getDensity(submittedBody);
              optionsBloc.getOptions(submittedBody);
            }
          },
          child: Text('Submit'),
        );
      });
    });
  }
}
