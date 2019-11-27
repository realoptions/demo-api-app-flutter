import 'package:flutter/material.dart';

class ShowProgressOrChild extends StatelessWidget{
  ShowProgressOrChild({
    Key key,
    @required this.child,
    @required this.isInProgress
  });
  final Widget child;
  final bool isInProgress;
  @override
  Widget build(BuildContext context){
    return isInProgress?Center(child:CircularProgressIndicator()):child;
  }
}