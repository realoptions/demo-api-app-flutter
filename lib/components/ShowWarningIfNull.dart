import 'package:flutter/material.dart';

class ShowWarningIfNull extends StatelessWidget{
  ShowWarningIfNull({
    Key key,
    @required this.child,
    @required this.data
  });
  final Widget child;
  final dynamic data;
  @override
  Widget build(BuildContext context){
    return this.data==null?Center(child:Text("Please submit parameters!")):child;
  }
}