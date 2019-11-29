import 'package:flutter/material.dart';
import 'package:demo_api_app_flutter/scaffold.dart';
import 'package:demo_api_app_flutter/blocs/bloc_provider.dart';
import 'package:demo_api_app_flutter/blocs/select_model_bloc.dart';
import 'package:demo_api_app_flutter/blocs/api_bloc.dart';
import 'package:demo_api_app_flutter/pages/intro.dart';

void main() => runApp(MyApp());
const String title = "Options";

class MyApp extends StatelessWidget {
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
            )),
        home: BlocProvider<ApiBloc>(bloc: ApiBloc(), child: StartupPage()));
  }
}

class StartupPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ApiBloc bloc = BlocProvider.of<ApiBloc>(context);
    return StreamBuilder(
        stream: bloc.outHomeState,
        initialData: HomeViewState.Busy,
        builder: (buildContext, snapshot) {
          switch (snapshot.data) {
            case HomeViewState.Busy:
              return Center(child: CircularProgressIndicator());
            case HomeViewState.DataRetrieved:
              return BlocProvider<SelectModelBloc>(
                  //even though AppScaffold doesn't need this, its children will
                  bloc: SelectModelBloc(),
                  child: AppScaffold(title: title));
            case HomeViewState.NoData:
              return Introduction(); //should automatically get the "ApiBloc" since the parent has it
            default:
              return Center(
                  child: CircularProgressIndicator()); //will never get here
          }
        });
  }
}
