import 'dart:io';

import 'package:flutter/material.dart';
import 'package:demo_api_app_flutter/services/api_key.dart' as auth;
import 'package:demo_api_app_flutter/app_bar.dart' as app_bar;
import 'package:demo_api_app_flutter/pages/intro.dart' as intro;
import 'package:demo_api_app_flutter/pages/form.dart' as form;
import 'package:demo_api_app_flutter/services/data_models.dart' as data_models;
import 'dart:async';
import 'package:demo_api_app_flutter/pages/options.dart' as options;
import 'package:demo_api_app_flutter/pages/density.dart' as density;
import 'package:demo_api_app_flutter/services/api_consume.dart' as api;
void main() => runApp(MyApp());
enum HomeViewState { Busy, DataRetrieved, NoData }
class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
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


const List<String> choices = const <String>[
  "Heston",
  "CGMY",
  "Merton"
];

class MyScaffold extends StatefulWidget {
  MyScaffold({
    Key key, 
    @required this.model, 
    @required this.title,
    @required this.onSelect,
    @required this.onApiChange,
    @required this.pages
  });
  final String model;
  final String title;
  final Function onSelect;
  final Function onApiChange;
  final List<Widget> pages;
  @override
  _MyScaffold createState() => _MyScaffold();
}

class _MyScaffold extends State<MyScaffold>{
  int _index=0;
  void _setPage(int index){
    setState((){
      _index=index;
    });
  }
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: app_bar.MyAppBar(
        title: widget.title,
        onApiKeyChange: widget.onApiChange,
        selectedModel: widget.model,
        onSelection: widget.onSelect,
        choices: choices
      ),
      body: widget.pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        items:const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.input), title:Text("Entry")),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), title:Text("Density")),
          BottomNavigationBarItem(icon: Icon(Icons.scatter_plot), title:Text("Prices")),
        ],
        currentIndex: _index,
        onTap: _setPage,
      )
    );
  }
}
class ShowProgressOrChild extends StatelessWidget{
  ShowProgressOrChild({
    Key key,
    @required this.child,
    @required this.isInProgress
  });
  Widget child;
  bool isInProgress;
  @override
  Widget build(BuildContext context){
    return isInProgress?Center(child:CircularProgressIndicator()):child;
  }
}
class HoldDataState extends StatefulWidget{
  HoldDataState({
    Key key,
    @required this.model,
    @required this.apiKey,
    @required this.title,
    @required this.snapshot,
    @required this.onSelect,
    @required this.onApiChange,
  });
  final String model;
  final String apiKey;
  final String title;
  final AsyncSnapshot snapshot;
  final Function onSelect;
  final Function onApiChange;
  @override
  _HoldDataState createState() => _HoldDataState();
}
class _HoldDataState extends State<HoldDataState>{
  data_models.ModelResults _density;
  data_models.ModelResults _callPrices;
  data_models.ModelResults _putPrices;
  bool _isFetchingData=false;
  Map<String, form.SubmitItems>_mapOfValues={};
  Function(String a, num b) _onFormSave(data_models.InputType inputType){
    return (String name, num value){
      _mapOfValues[name]=form.SubmitItems(
        inputType:inputType, 
        value:value
      );
    };
  }
  /*void _setData(Map<String, data_models.ModelResults> values){
    print(values);
    setState(() {
      _callPrices=values["call"];
      _putPrices=values["put"];
      _density=values["density"];
    });
  }*/
  void _setData(Future<Map<String, data_models.ModelResults>> getData){
    setState((){
      _isFetchingData=true;
    });
    getData.then((values){
      setState(() {
        _callPrices=values["call"];
        _putPrices=values["put"];
        _density=values["density"];
        _isFetchingData=false;
      });
    });
  }
  List<Widget> _getPages(AsyncSnapshot snapshot){
    return [
      ShowProgressOrChild(
        child: form.InputForm(
          model:widget.model, 
          apiKey: widget.apiKey, 
          onSubmit: _setData, 
          snapshot: snapshot,
          formValues: _mapOfValues,
          onSave: _onFormSave
        ),
        isInProgress: _isFetchingData,
      ),
      ShowProgressOrChild(
        child: density.ShowDensity(density:_density),
        isInProgress: _isFetchingData,
      ),
      ShowProgressOrChild(
        child: options.ShowOptionPrices(
          callOption: _callPrices,
          putOption: _putPrices,
        ),
        isInProgress: _isFetchingData,
      ),
    ];
  }
  @override
  Widget build(BuildContext context) {
    List<Widget> pages=_getPages(widget.snapshot);
    return MyScaffold(
      model: widget.model,
      title: widget.title,
      onSelect: widget.onSelect,
      onApiChange: widget.onApiChange,
      pages:pages
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  final StreamController<HomeViewState> stateController = StreamController<HomeViewState>();
  String _selectedModel=choices[0];
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
        print(apiKeyList.first.key);
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
        if (!snapshot.hasData || snapshot.data ==HomeViewState.Busy) {
          return Center(child: CircularProgressIndicator());
        }

        // use explicit state instead of checking the lenght
        if(snapshot.data ==HomeViewState.NoData) {
          return intro.Introduction(onApiKeyChange: _setKey,);
        }

        return FutureBuilder<data_models.InputConstraints>(
          future: api.fetchConstraints(_selectedModel, _key),
          builder: (
            BuildContext context, 
            AsyncSnapshot<data_models.InputConstraints> snapshot
          ){
            return HoldDataState(
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