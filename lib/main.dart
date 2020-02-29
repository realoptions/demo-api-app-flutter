import 'package:realoptions/models/progress.dart';
//import 'package:realoptions/services/persistant_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:realoptions/components/AppScaffold.dart';
import 'package:realoptions/blocs/bloc_provider.dart';
import 'package:realoptions/blocs/select_model_bloc.dart';
import 'package:realoptions/blocs/api_bloc.dart';
import 'package:realoptions/pages/intro.dart';
import 'package:firebase_auth/firebase_auth.dart';

//import 'package:firebase_analytics/firebase_analytics.dart';
//import 'package:firebase_analytics/observer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp(firebaseAuth: FirebaseAuth.instance));
}

const String title = "Options";

/*home: SplashPage(),
      routes: <String, WidgetBuilder>{
        '/task': (BuildContext context) => TaskPage(title: 'Task'),
        '/home': (BuildContext context) => HomePage(title: 'Home'),
        '/login': (BuildContext context) => LoginPage(),
        '/register': (BuildContext context) => RegisterPage(),
      });
  */
class MyApp extends StatelessWidget {
  // static FirebaseAnalytics analytics = FirebaseAnalytics();
  //static FirebaseAnalyticsObserver observer =
  //    FirebaseAnalyticsObserver(analytics: analytics);
  MyApp({this.firebaseAuth});
  final FirebaseAuth firebaseAuth;
  //final PersistentStorage apiStorage;
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
        home: BlocProvider<ApiBloc>(
            bloc: ApiBloc(firebaseAuth: firebaseAuth), child: StartupPage()));
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
