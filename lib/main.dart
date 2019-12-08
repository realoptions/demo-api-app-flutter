import 'package:realoptions/models/progress.dart';
import 'package:realoptions/services/api_key_service.dart';
import 'package:flutter/material.dart';
import 'package:realoptions/scaffold.dart';
import 'package:realoptions/blocs/bloc_provider.dart';
import 'package:realoptions/blocs/select_model_bloc.dart';
import 'package:realoptions/blocs/api_bloc.dart';
import 'package:realoptions/pages/intro.dart';

void main() => runApp(MyApp(db: ApiDB()));
const String title = "Options";

class MyApp extends StatelessWidget {
  MyApp({this.db});
  final ApiDB db;
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Demo Option Pricing App',
        theme: ThemeData(
            primarySwatch: Colors.teal,
            accentColor: Colors.orange,
            buttonTheme: ButtonThemeData(
              buttonColor: Colors.orange,
            ),
            textTheme: TextTheme(
              body1: TextStyle(
                fontSize: 15.0,
              ),
            )),
        home:
            BlocProvider<ApiBloc>(bloc: ApiBloc(db: db), child: StartupPage()));
  }
}

class StartupPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ApiBloc bloc = BlocProvider.of<ApiBloc>(context);
    return StreamBuilder<StreamProgress>(
        stream: bloc.outHomeState,
        initialData: StreamProgress.Busy,
        builder: (buildContext, snapshot) {
          if (snapshot.hasError) {
            //should never get here
            return Center(child: Text(snapshot.error.toString()));
          }
          switch (snapshot.data) {
            case StreamProgress.Busy:
              return Center(child: CircularProgressIndicator());
            case StreamProgress.DataRetrieved:
              return BlocProvider<SelectModelBloc>(
                  bloc: SelectModelBloc(), child: AppScaffold(title: title));
            case StreamProgress.NoData:
              return Introduction();
            default:
              return Center(
                  child: CircularProgressIndicator()); //will never get here
          }
        });
  }
}
