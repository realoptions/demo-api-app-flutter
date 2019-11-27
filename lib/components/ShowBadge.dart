
import 'package:flutter/material.dart';
import 'package:badges/badges.dart';
class ShowBadge extends StatelessWidget{
  ShowBadge({
    @required this.showBadge,
    @required this.icon
  });
  final Widget icon;
  final bool showBadge;
  @override
  Widget build(BuildContext context){
    return this.showBadge?Badge(
      badgeContent: Text(''),
      child: icon,
      badgeColor: Colors.orange,
    ):icon;
  }
}