import 'package:flutter/material.dart';
import 'package:demo_api_app_flutter/storage/api_key.dart';
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
  int _counter = 0;
  String _selectedModel=choices[0];
  bool _keyIsCorrect=false;
  String _key="";
  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }
  void _select(String choice) {
    setState((){
      _selectedModel=choice;
    });
    
  }

  Future<List<ApiKey>> _getKey() async{
    return await retrieveKey();    
  }
  void _setKeyCorrect() {
    setState((){
      _keyIsCorrect=true;
    });
  }

  Widget _buildTab(hasKey) {
    
    if(hasKey){
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'You have cliecked the button this many times:',
          ),
          Text(
            '$_counter',
            style: Theme.of(context).textTheme.display1,
          ),
        ],
      );
    }
    else{
      return Text("You need to add your API key");
    }
  }
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return FutureBuilder<List<ApiKey> >(
      builder: (context, snapshot){
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return Text('Should never get here');
          case ConnectionState.active:
          case ConnectionState.waiting:
            return Text('Awaiting result...');
          case ConnectionState.done:
            return DefaultTabController(
              length:3, 
              child: Scaffold(
                appBar: AppBar(
                  // Here we take the value from the MyHomePage object that was created by
                  // the App.build method, and use it to set our appbar title.
                  title: Text(widget.title+": "+_selectedModel),
                  bottom: TabBar(
                    tabs: [
                      Tab(icon: Icon(Icons.directions_car)),
                      Tab(icon: Icon(Icons.directions_transit)),
                      Tab(icon: Icon(Icons.directions_bike)),
                    ],
                  ),
                  actions: <Widget>[
                    IconButton(
                      icon: Icon(Icons.lock),
                      onPressed: () {
                        showDialog<void>(context: context, builder: (BuildContext context) {
                          return new AlertDialog(
                            contentPadding: const EdgeInsets.all(16.0),
                            content: new Row(
                              children: <Widget>[
                                new Expanded(
                                  child: new TextField(
                                    autofocus: true,
                                    onChanged: (String val){
                                      _key=val;
                                    },
                                    decoration: new InputDecoration(
                                        labelText: 'API Key'
                                    ),
                                  ),
                                )
                              ],
                            ),
                            actions: <Widget>[
                              new FlatButton(
                                  child: const Text('CANCEL'),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  }),
                              new FlatButton(
                                  child: const Text('SAVE'),
                                  onPressed: () async {
                                    await insertKey(ApiKey(id:1, key:_key));
                                    //_setKeyCorrect();
                                    Navigator.pop(context);
                                  })
                            ],
                          );
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.more_vert),
                      onPressed: () {
                        showModalBottomSheet<void>(context: context, builder: (BuildContext context) {
                          return ListView(
                            shrinkWrap: true,
                            children: choices.map((choice)=> RadioListTile<String>(
                                title: Text(choice),
                                value: choice,
                                groupValue: _selectedModel,
                                onChanged: (choice){
                                  //_select(choice);
                                  Navigator.pop(context);
                                }
                              )
                            ).toList()
                          );
                        });
                      },
                    ),
                  ],
                ),
                body: TabBarView(
                  children:[
                    _buildTab(snapshot.data.length>0),
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
          return null;//never gets here
      },
      future:_getKey()
    );
  }
}
