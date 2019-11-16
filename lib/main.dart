import 'package:flutter/material.dart';
import 'package:demo_api_app_flutter/storage/api_key.dart';
import 'package:demo_api_app_flutter/app_bar.dart';
import 'package:demo_api_app_flutter/pages/intro.dart';

void main() => runApp(MyApp());

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

class _MyHomePageState extends State<MyHomePage> {
  
  String _selectedModel=choices[0];
  String _key="";
  bool _isLoading=true;
  bool _isFirstLoad=true; //there has to be a better way than this...
  void _select(String choice) {
    setState((){
      _selectedModel=choice;
    });
  }
  void _setLoading(bool isLoading){
    setState((){
      _isLoading=isLoading;
    });
  }

  _getKey(){
    _setLoading(true);
    retrieveKey().then((apiKey){
      if(apiKey.length>0){
        print(apiKey.first.key);
        setState((){
          _key=apiKey.first.key;
        });
      }
      _setLoading(false);
      
    });    
  }

  _setKey(String apiKey){
    setState((){
      _key=apiKey;
    });
    insertKey(ApiKey(id: 1, key: apiKey));
    
  }
  

  @override
  Widget build(BuildContext context) {
    //_getKey();
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    if(_isFirstLoad){
      print("got to first load");
      _getKey();
      setState((){
        _isFirstLoad=false;
      });
    }
    if(_isLoading){
      return CircularProgressIndicator(value:null);
    }
    else{
      switch(_key){
        case "":
          return Introduction(onApiKeyChange: _setKey,);
        default:
          return DefaultTabController(
            length:3, 
            child: Scaffold(
              appBar: MyAppBar(
                title: widget.title,
                onApiKeyChange: _setKey,
                selectedModel: _selectedModel,
                onSelection: _select,
                choices: choices
              ),
              body: TabBarView(
                children:[
                  Text("Hello world"),
                  Icon(Icons.directions_transit),
                  Icon(Icons.directions_bike),
                ]
              
              ),
              floatingActionButton: FloatingActionButton(
                  onPressed: (){},//_incrementCounter,
                  tooltip: 'Increment',
                  child: Icon(Icons.add),
              ), // This trailing comma makes auto-formatting nicer for build methods.;
            )
          );
      }
      
    }
      //return null;//never gets here
  }
}
