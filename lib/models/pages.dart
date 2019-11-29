import 'package:flutter/material.dart';

class PageEntry {
  PageEntry({
    @required this.widget,
    @required this.icon,
    @required this.text,
  });
  final Widget widget;
  final Widget icon;
  final String text;
}
