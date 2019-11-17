import 'package:flutter/material.dart';

class Introduction extends StatefulWidget {
  Introduction({
    @required this.onApiKeyChange, 
  });

  final Function onApiKeyChange;  //takes string, returns void (sets state)
  @override
  _Introduction createState() => _Introduction();

}

class _Introduction extends State<Introduction> {
  
  String _apiKey="";

  void _onTextFieldChange(String text){
    setState((){
      _apiKey=text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
          children:[
            Expanded(
              child: new TextField(
                autofocus: false,
                onChanged: _onTextFieldChange,
                decoration: new InputDecoration(
                    labelText: 'API Key'
                ),
              ),
            ),

            new RaisedButton(
              child: const Text('SAVE'),
              onPressed: () {
                widget.onApiKeyChange(_apiKey);
              })
          ]
        )
    );
  }
}

