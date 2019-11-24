import 'package:flutter/material.dart';
import 'package:demo_api_app_flutter/services/api_key.dart' as auth;
import 'package:demo_api_app_flutter/app_bar.dart' as app_bar;
import 'package:demo_api_app_flutter/pages/intro.dart' as intro;
import 'package:demo_api_app_flutter/pages/form.dart' as form;
import 'package:demo_api_app_flutter/services/data_models.dart' as data_models;
import 'dart:async';
import 'package:demo_api_app_flutter/pages/options.dart' as options;
import 'package:demo_api_app_flutter/pages/density.dart' as density;

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

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}


const List<String> choices = const <String>[
  "Heston",
  "CGMY",
  "Merton"
];


//TODO!  Make the movement between inputs NOT require a reload of the form
// ONLY make HTTP call if model type has changed.
class _MyHomePageState extends State<MyHomePage> {
  final StreamController<HomeViewState> stateController = StreamController<HomeViewState>();
  String _selectedModel=choices[0];
  String _key="";
  int _index=0;
  data_models.ModelResults _density;
  data_models.ModelResults _callPrices;
  data_models.ModelResults _putPrices;
  void _select(String choice) {
    setState((){
      _selectedModel=choice;
    });
  }
  void _setPage(int index){
    setState((){
      _index=index;
    });
  }
  _getKey(bool hasError){
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
  _setData(List<data_models.ModelResults> values){
    setState(() {
      _callPrices=values[0];
      _putPrices=values[1];
      _density=values[2];
    });
  }

  _setKey(String apiKey){
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
    List<Widget> pages = <Widget>[
      form.InputForm(model:_selectedModel, apiKey: _key, onSubmit: _setData),
      density.ShowDensity(density:_density),
      options.ShowOptionPrices(
        callOption: _callPrices,
        putOption: _putPrices,
      )
    ];

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

        return Scaffold(
          appBar: app_bar.MyAppBar(
            title: widget.title,
            onApiKeyChange: _setKey,
            selectedModel: _selectedModel,
            onSelection: _select,
            choices: choices
          ),
          body: pages[_index],
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
    );
  }
}
