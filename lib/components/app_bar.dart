import 'package:flutter/material.dart';
import 'package:realoptions/blocs/api_bloc.dart';
import 'package:realoptions/blocs/select_model_bloc.dart';
import 'package:realoptions/blocs/bloc_provider.dart';
import 'package:realoptions/models/models.dart';

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
            key: Key("AppBarComponent"),
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
        return AlertDialog(
          content: Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  autofocus: true,
                  onChanged: apiBloc.setApiKey,
                  decoration: InputDecoration(labelText: 'API Key'),
                  initialValue: apiBloc.getApiKey(),
                ),
              )
            ],
          ),
          actions: <Widget>[
            FlatButton(
                child: const Text('CANCEL'),
                onPressed: () {
                  Navigator.pop(context);
                }),
            FlatButton(
                child: const Text('SAVE'),
                onPressed: () {
                  Navigator.pop(context);
                  apiBloc.saveApiKey();
                })
          ],
        );
      });
}