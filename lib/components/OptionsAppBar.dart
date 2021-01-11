import 'package:flutter/material.dart';
import 'package:realoptions/blocs/select_model/select_model_bloc.dart';
import 'package:realoptions/blocs/bloc_provider.dart';
import 'package:realoptions/models/models.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OptionsAppBar extends StatelessWidget with PreferredSizeWidget {
  OptionsAppBar({@required this.title, @required this.choices});
  final String title;
  final List<Model> choices;
  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectModelBloc, Model>(
        builder: (context, selectedModel) {
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
                                    '''This app calculates option prices for three models: Heston, CGMY with a diffusion and a stochastic clock, and Merton jump-diffusion with stochastic clock.  It uses Fang and Oosterlee's algorithm for efficient pricing across many strikes.'''),
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
                                  context
                                      .read<SelectModelBloc>()
                                      .setModel(choice);
                                  Navigator.pop(context);
                                }))
                            .toList());
                  });
            },
          ),
        ],
      );
    });
    /*return StreamBuilder<Model>(
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
                                        '''This app calculates option prices for three models: Heston, CGMY with a diffusion and a stochastic clock, and Merton jump-diffusion with stochastic clock.  It uses Fang and Oosterlee's algorithm for efficient pricing across many strikes.'''),
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
        });*/
  }
}

_launchDocs() async {
  const url =
      'https://raw.githubusercontent.com/realoptions/option_price_faas/master/techdoc/OptionCalculation.pdf';
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}
