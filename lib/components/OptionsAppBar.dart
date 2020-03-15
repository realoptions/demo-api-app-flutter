import 'package:flutter/material.dart';
import 'package:realoptions/blocs/select_model_bloc.dart';
import 'package:realoptions/blocs/bloc_provider.dart';
import 'package:realoptions/models/models.dart';
import 'package:url_launcher/url_launcher.dart';

class OptionsAppBar extends StatelessWidget with PreferredSizeWidget {
  OptionsAppBar({@required this.title, @required this.choices});
  final String title;
  final List<Model> choices;
  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) {
    final SelectModelBloc selectBloc =
        BlocProvider.of<SelectModelBloc>(context);
    return StreamBuilder<Model>(
        stream: selectBloc.outSelectedModel,
        initialData: this.choices[0],
        builder: (buildContext, snapshot) {
          var selectedModel = snapshot.data;
          return AppBar(
            key: Key("AppBarComponent"),
            title: Text(this.title + ": " + selectedModel.label),
            actions: <Widget>[
              IconButton(
                  icon: Icon(Icons.help),
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                              title: Text('Help'),
                              content: SingleChildScrollView(
                                child: ListBody(
                                  children: <Widget>[
                                    Text(
                                        'Asset is the dollar value of the underlying.'),
                                    Text(
                                        'Maturity is the time in years until the option expires.'),
                                    Text(
                                        'num_u is exponent for the precision of the numeric inversion.  For example, 8 represents 2^8=256.'),
                                    Text(
                                        'Quantile is used for VaR and expected shortfall.  For example, 0.05 is a 95% VaR.'),
                                    Text(
                                        'Rate is the (annualized) risk free rate.'),
                                    Text(
                                        'The remaining variables are dependent on the model.'),
                                    RaisedButton(
                                      onPressed: _launchDocs,
                                      child: Text('References'),
                                    ),
                                  ],
                                ),
                              ));
                        });
                  }),
              IconButton(
                icon: Icon(Icons.more_vert),
                onPressed: () {
                  showModalBottomSheet<void>(
                      context: context,
                      builder: (BuildContext context) {
                        return ListView(
                            shrinkWrap: true,
                            children: this
                                .choices
                                .map((choice) => RadioListTile<Model>(
                                    title: Text(choice.label),
                                    value: choice,
                                    groupValue: selectedModel,
                                    onChanged: (choice) {
                                      selectBloc.setModel(choice);
                                      Navigator.pop(context);
                                    }))
                                .toList());
                      });
                },
              ),
            ],
          );
        });
  }
}

_launchDocs() async {
  const url =
      'https://github.com/phillyfan1138/fang_oost_cal_charts/raw/master/docs/OptionCalculation.pdf';
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}
