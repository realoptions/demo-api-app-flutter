import 'file:///home/daniel/Documents/code/finside/demo-api-app-flutter/test/components/options_bloc.dart';
import 'package:realoptions/blocs/select_page/select_page_bloc.dart';
import 'package:realoptions/models/pages.dart';
import 'package:flutter/material.dart';
import 'package:realoptions/components/CustomPadding.dart';
import 'package:realoptions/components/CustomTextFields.dart';
import 'package:realoptions/models/forms.dart';
import 'package:realoptions/blocs/form/form_bloc.dart';
import 'package:realoptions/blocs/bloc_provider.dart';
import 'package:realoptions/blocs/density/density_bloc.dart';
import 'package:realoptions/models/progress.dart';

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
    FormBloc bloc = BlocProvider.of<FormBloc>(context);
    return StreamBuilder<Iterable<FormItem>>(
      stream: bloc.outFormController,
      initialData: [],
      builder: (buildContext, snapshot) {
        List<Widget> formFields =
            snapshot.data.map<Widget>((FormItem formItem) {
          return getField(context, bloc.onSave, formItem.valueAtLastSubmit,
              formItem.constraint);
        }).toList();
        formFields.add(PaddingForm(child: FormButton(formKey: _formKey)));
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

class FormButton extends StatelessWidget {
  FormButton({@required this.formKey});
  final GlobalKey<FormState> formKey;
  @override
  Widget build(BuildContext context) {
    FormBloc bloc = BlocProvider.of<FormBloc>(context);
    DensityBloc densityBloc = BlocProvider.of<DensityBloc>(context);
    OptionsBloc optionsBloc = BlocProvider.of<OptionsBloc>(context);
    SelectPageBloc pageBloc = BlocProvider.of<SelectPageBloc>(context);

    return StreamBuilder<StreamProgress>(
        stream: densityBloc.outDensityProgress,
        builder: (buildContext, snapshotDensity) {
          return StreamBuilder<StreamProgress>(
              stream: optionsBloc.outOptionsProgress,
              builder: (buildContext, snapshotOptions) {
                if (snapshotDensity.data == StreamProgress.Busy &&
                    snapshotOptions.data == StreamProgress.Busy) {
                  return CircularProgressIndicator();
                }
                return RaisedButton(
                  onPressed: () {
                    // Validate returns true if the form is valid, or false
                    // otherwise.
                    if (formKey.currentState.validate()) {
                      formKey.currentState.save();
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
                );
              });
        });
  }
}
