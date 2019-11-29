import 'package:demo_api_app_flutter/components/CustomPadding.dart';
import 'package:flutter/material.dart';
import 'package:demo_api_app_flutter/blocs/bloc_provider.dart';
import 'package:demo_api_app_flutter/blocs/api_bloc.dart';

class Introduction extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ApiBloc bloc = BlocProvider.of<ApiBloc>(context);
    return Scaffold(
        body: Column(children: <Widget>[
      PaddingForm(
          child: new TextField(
              decoration: new InputDecoration(labelText: 'API Key'),
              onChanged: bloc.setApiKey)),
      PaddingForm(
          child: RaisedButton(
              child: const Text('Save'), onPressed: bloc.saveApiKey))
    ]));
  }
}
