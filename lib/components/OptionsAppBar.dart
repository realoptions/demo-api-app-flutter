import 'package:flutter/material.dart';
import 'package:realoptions/blocs/select_model_bloc.dart';
import 'package:realoptions/blocs/bloc_provider.dart';
import 'package:realoptions/models/models.dart';

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
