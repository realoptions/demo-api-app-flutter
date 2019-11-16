import 'package:flutter/material.dart';

class MyAppBar extends StatefulWidget with PreferredSizeWidget{
  MyAppBar({
    @required this.title, 
    @required this.onApiKeyChange, 
    @required this.selectedModel, 
    @required this.onSelection,
    @required this.choices
  });

  final String title;
  final Function onApiKeyChange;  //takes string, returns void (sets state)
  final String selectedModel;
  final Function onSelection;
  final List<String> choices;
  @override
  _MyAppBar createState() => _MyAppBar();
  @override
  Size get preferredSize => Size.fromHeight(100); //how to make this dynamic??
}

class _MyAppBar extends State<MyAppBar> {
  
  String _apiKey="";

  void _onTextFieldChange(String text){
    setState((){
      _apiKey=text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // Here we take the value from the MyHomePage object that was created by
      // the App.build method, and use it to set our appbar title.
      title: Text(widget.title+": "+widget.selectedModel),
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
                        onChanged: _onTextFieldChange,
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
                        await widget.onApiKeyChange(_apiKey);
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
                children: widget.choices.map((choice)=> RadioListTile<String>(
                    title: Text(choice),
                    value: choice,
                    groupValue: widget.selectedModel,
                    onChanged: (choice){
                      widget.onSelection(choice);
                      Navigator.pop(context);
                    }
                  )
                ).toList()
              );
            });
          },
        ),
      ],
    );
  }
}

