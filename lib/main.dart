import 'package:realoptions/blocs/api/api_events.dart';
import 'package:realoptions/blocs/api/api_state.dart';
import 'package:realoptions/models/progress.dart';
import 'package:flutter/material.dart';
import 'package:realoptions/components/AppScaffold.dart';
//import 'package:realoptions/blocs/bloc_provider.dart';
import 'package:realoptions/blocs/select_model/select_model_bloc.dart';
import 'package:realoptions/blocs/api/api_bloc.dart';
import 'package:realoptions/pages/intro.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc/bloc.dart';
import 'package:realoptions/repositories/api_repository.dart';
import 'blocs/simple_bloc_observer.dart';
//import 'package:firebase_core/firebase_core.dart';

void main() {
  Bloc.observer = SimpleBlocObserver();
  WidgetsFlutterBinding.ensureInitialized();
  //await Firebase.initializeApp();
  runApp(MyApp());

  //WidgetsFlutterBinding.ensureInitialized();
  //runApp(MyApp(firebaseAuth: FirebaseAuth.instance));
}

const String title = "Options";

class MyApp extends StatelessWidget {
  //MyApp({this.firebaseAuth});
  //final FirebaseAuth firebaseAuth;
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
              bodyText2: TextStyle(
                fontSize: 15.0,
              ),
            )),
        home: BlocProvider<ApiBloc>(
            create: (context) {
              return ApiBloc(
                  firebaseAuth: FirebaseAuth.instance,
                  apiRepository: ApiRepository())
                ..add(ApiEvents.RequestApiKey);
            },
            child: StartupPage()));
  }
}

class StartupPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ApiBloc, ApiState>(
      builder: (context, data) {
        if (data is ApiError) {
          return Center(child: Text(data.apiError.toString()));
        } else if (data is ApiIsFetching) {
          return Center(child: CircularProgressIndicator());
        } else if (data is ApiNoData) {
          return Introduction();
        } else if (data is ApiToken) {
          return BlocProvider<SelectModelBloc>(
              create: (context) {
                return SelectModelBloc();
              },
              child: AppScaffold(title: title, apiKey: data.token));
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );

    /*
    StreamBuilder<StreamProgress>(
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
        });*/
  }
}
