import 'package:flutter/material.dart';


class PaddingForm extends StatelessWidget{
  const PaddingForm({
    Key key,
    this.child,
  }) : super(key: key);
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 16.0),
      child: child
    );
  }
}