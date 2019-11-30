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

class PageState {
  PageState({this.index, this.showBadges});
  int index;
  final List<bool> showBadges;
}

const int DENSITY_PAGE = 1;
const int OPTIONS_PAGE = 2;
