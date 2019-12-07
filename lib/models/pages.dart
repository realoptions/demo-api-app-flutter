import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:quiver/core.dart' show hash2;

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
  PageState({@required this.index, @required this.showBadges});
  int index;
  final List<bool> showBadges;
  @override
  bool operator ==(other) {
    if (other is! PageState) {
      return false;
    }
    if (index != other.index) {
      return false;
    }
    if (!listEquals(showBadges, other.showBadges)) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => hash2(index, showBadges);
}

const int DENSITY_PAGE = 1;
const int OPTIONS_PAGE = 2;
