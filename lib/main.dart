import 'package:flutter/material.dart';
import 'package:demo_api_app_flutter/services/api_key.dart' as auth;
import 'package:demo_api_app_flutter/pages/intro.dart' as intro;
import 'package:demo_api_app_flutter/models/forms.dart' as form_model;
import 'dart:async';
import 'package:demo_api_app_flutter/services/api_consume.dart' as api;
import 'package:demo_api_app_flutter/scaffold.dart' as scaffold;

void main() => runApp(MyApp());
enum HomeViewState { Busy, DataRetrieved, NoData }
class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        accentColor: Colors.orange,
        buttonTheme: ButtonThemeData(
           buttonColor: Colors.orange,
        )
      ),
      home: MyHomePage(title: 'Options'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> {
  final StreamController<HomeViewState> stateController = StreamController<HomeViewState>();
  String _selectedModel=scaffold.choices[0];
  String _key="";
  void _select(String choice) {
    setState((){
      _selectedModel=choice;
    });
  }
  void _getKey(bool hasError){
    stateController.add(HomeViewState.Busy);
    if (hasError) {
      return stateController.addError(
          'An error occurred while fetching the data. Please try again later.');
    }
    auth.retrieveKey().then((apiKeyList){
      if(apiKeyList.length>0 && apiKeyList.first.key!=""){
        //print(apiKeyList.first.key);
        _key=apiKeyList.first.key;
        stateController.add(HomeViewState.DataRetrieved);
      }
      else{
        stateController.add(HomeViewState.NoData);
      }      
    });    
  }
  Future<void> _setKey(String apiKey){
    _key=apiKey;
    if(_key==""){
      stateController.add(HomeViewState.NoData);
    }
    else{
      stateController.add(HomeViewState.DataRetrieved);
    }
    return auth.insertKey(auth.ApiKey(id: 1, key: apiKey)).catchError((err){
      return stateController.addError(
          'An error occurred while fetching the data. Please try again later.');
    });
  }
  @override
  void initState() {
    _getKey(false);
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: stateController.stream,
      builder: (buildContext, snapshot) {

        if(snapshot.hasError) {
          Scaffold.of(context).showSnackBar(SnackBar(content: Text(snapshot.error)));
          return intro.Introduction(onApiKeyChange: _setKey,);
        }

        // Use busy indicator if there's no state yet, and when it's busy
        if (!snapshot.hasData || snapshot.data == HomeViewState.Busy) {
          return Center(child: CircularProgressIndicator());
        }

        // use explicit state instead of checking the lenght
        if(snapshot.data == HomeViewState.NoData) {
          return intro.Introduction(onApiKeyChange: _setKey,);
        }

        return FutureBuilder<form_model.InputConstraints>(
          future: api.fetchConstraints(_selectedModel, _key),
          builder: (
            BuildContext context, 
            AsyncSnapshot<form_model.InputConstraints> snapshot
          ){
            return scaffold.HoldDataState(
              apiKey: _key,
              snapshot: snapshot,
              model: _selectedModel,
              title: widget.title,
              onSelect: _select,
              onApiChange: _setKey,
            );
          }
        );
      }
    );
  }
}