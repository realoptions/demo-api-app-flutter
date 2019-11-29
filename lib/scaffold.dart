import 'package:flutter/material.dart';
import 'package:demo_api_app_flutter/app_bar.dart' as app_bar;
import 'package:demo_api_app_flutter/pages/form.dart' as form;
import 'package:demo_api_app_flutter/pages/options.dart' as options;
import 'package:demo_api_app_flutter/pages/density.dart' as density;
import 'package:demo_api_app_flutter/components/ShowBadge.dart' as badge;
import 'package:demo_api_app_flutter/models/response.dart' as response_model;
import 'package:demo_api_app_flutter/models/forms.dart' as form_model;
import 'package:demo_api_app_flutter/components/ShowProgressOrChild.dart' as progressOrChild;
import 'package:demo_api_app_flutter/components/ShowWarningIfNull.dart' as showWarning;

const List<String> choices = const <String>[
  "Heston",
  "CGMY",
  "Merton"
];
class PageEntry{
  PageEntry({
    @required this.widget, 
    @required this.icon, 
    @required this.text, 
  });
  final Widget widget;
  final Widget icon;
  final String text;
}
class MyScaffold extends StatelessWidget{
  const MyScaffold({
    Key key, 
    @required this.model, 
    @required this.title,
    @required this.onSelect,
    @required this.onApiChange,
    @required this.pages,
    @required this.onTap,
    @required this.index,
  });
  final String model;
  final String title;
  final Function onSelect;
  final Function onTap;
  final Function onApiChange;
  final List<PageEntry> pages;
  final int index;
  //final PageStorageBucket bucket;//this doesn't appear to work
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: app_bar.MyAppBar(
        title: this.title,
        onApiKeyChange: this.onApiChange,
        selectedModel: this.model,
        onSelection: this.onSelect,
        choices: choices
      ),
      body: this.pages[this.index].widget,
      bottomNavigationBar: BottomNavigationBar(
        items:this.pages.map((PageEntry entry){
          return BottomNavigationBarItem(
            icon: entry.icon, 
            title:Text(entry.text)
          );
        }).toList(),
        currentIndex: this.index,
        onTap: this.onTap,
      )
    );
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
  response_model.ModelResults _density;
  response_model.ModelResults _callPrices;
  response_model.ModelResults _putPrices;
  int _index=0;
  bool _isFetchingData=false;
  Map<String, form.SubmitItems>_mapOfValues={};
  final PageStorageBucket _bucket=PageStorageBucket();
  Map<int, bool> _showBadge={
    0:false,
    1:false,
    2:false
  };
  Function(String a, num b) _onFormSave(form_model.InputType inputType){
    return (String name, num value){
      _mapOfValues[name]=form.SubmitItems(
        inputType:inputType, 
        value:value
      );
    };
  }
  void _setData(Future<Map<String, response_model.ModelResults>> getData){
    setState((){
      _isFetchingData=true;
    });
    getData.then((values){
      setState(() {
        _callPrices=values["call"];
        _putPrices=values["put"];
        _density=values["density"];
        _isFetchingData=false;
        _showBadge={
          0:true,
          1:true,
          2:true
        };
      });
    });
  }
  void _onTap(int index){
    setState((){
      _index=index;
      _showBadge={
        ..._showBadge,
        _index:false
      };
    });    
  }
  List<PageEntry> _getPages(
    AsyncSnapshot snapshot,
  ){
    return [
      PageEntry(
        widget: PageStorage(
          child: progressOrChild.ShowProgressOrChild(
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
          bucket: _bucket
        ),
        icon: Icon(Icons.input),
        text: "Entry",
      ),
      PageEntry(
        widget:PageStorage(
          child: progressOrChild.ShowProgressOrChild(
            child: showWarning.ShowWarningIfNull(
              child:density.ShowDensity(density: _density),
              data: _density,
            ),
            isInProgress: _isFetchingData,
          ),
          bucket: _bucket
        ),
        icon: badge.ShowBadge(
          icon:Icon(Icons.show_chart),
          showBadge: _showBadge[1]
        ),
        text: "Density"
      ),
      PageEntry(
        widget:PageStorage(
          child: progressOrChild.ShowProgressOrChild(
            child: showWarning.ShowWarningIfNull(
              child: options.ShowOptionPrices(
                callOption: _callPrices,
                putOption: _putPrices,
              ),
              data: _callPrices,
            ),
            isInProgress: _isFetchingData,
          ),
          bucket: _bucket
        ),
        icon: badge.ShowBadge(
          icon:Icon(Icons.scatter_plot),
          showBadge: _showBadge[2]
        ),
        text:"Prices",
      )
    ];
  }
    
  @override
  Widget build(BuildContext context) {
    List<PageEntry> pages=_getPages(widget.snapshot);
    return MyScaffold(
      model: widget.model,
      title: widget.title,
      onSelect: widget.onSelect,
      onApiChange: widget.onApiChange,
      pages: pages,
      onTap:_onTap,
      index: _index,
    );
  }
}