import 'package:flutter/material.dart';
import 'package:demo_api_app_flutter/blocs/api_bloc.dart';
import 'package:demo_api_app_flutter/blocs/select_model_bloc.dart';
import 'package:demo_api_app_flutter/blocs/bloc_provider.dart';
import 'package:demo_api_app_flutter/models/models.dart';

class OptionPriceAppBar extends StatelessWidget with PreferredSizeWidget {
  OptionPriceAppBar({@required this.title, @required this.choices});
  final String title;
  final List<Model> choices;
  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) {
    final SelectModelBloc selectBloc =
        BlocProvider.of<SelectModelBloc>(context);
    final ApiBloc apiBloc = BlocProvider.of<ApiBloc>(context);
    return StreamBuilder<Model>(
        stream: selectBloc.outSelectedModel,
        initialData: this.choices[0],
        builder: (buildContext, snapshot) {
          var selectedModel = snapshot.data;
          return AppBar(
            title: Text(this.title + ": " + selectedModel.label),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.lock),
                onPressed: () {
                  _showDialog(context, apiBloc);
                },
              ),
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
                                .map((choice) => RadioListTile<String>(
                                    title: Text(choice.label),
                                    value: choice.value,
                                    groupValue: selectedModel.value,
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

Future<void> _showDialog(BuildContext context, ApiBloc apiBloc) {
  return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return new AlertDialog(
          //contentPadding: const EdgeInsets.all(16.0),
          content: new Row(
            children: <Widget>[
              new Expanded(
                child: new TextField(
                  autofocus: true,
                  onChanged: apiBloc.setApiKey,
                  decoration: new InputDecoration(labelText: 'API Key'),
                ),
              )
            ],
          ),
          actions: <Widget>[
            new FlatButton(
                child: const Text('CANCEL'),
                onPressed: () {
                  Navigator.pop(context);
                }),
            new FlatButton(
                child: const Text('SAVE'),
                onPressed: () {
                  Navigator.pop(context);
                  apiBloc.saveApiKey();
                })
          ],
        );
      });
}
