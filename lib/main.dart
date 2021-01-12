import 'package:realoptions/blocs/api/api_events.dart';
import 'package:realoptions/blocs/api/api_state.dart';
import 'package:flutter/material.dart';
import 'package:realoptions/components/AppScaffold.dart';
import 'package:realoptions/blocs/select_model/select_model_bloc.dart';
import 'package:realoptions/blocs/api/api_bloc.dart';
import 'package:realoptions/pages/intro.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc/bloc.dart';
import 'package:realoptions/repositories/api_repository.dart';
import 'blocs/simple_bloc_observer.dart';

void main() {
  Bloc.observer = SimpleBlocObserver();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

const String title = "Options";

class MyApp extends StatelessWidget {
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
  }
}
