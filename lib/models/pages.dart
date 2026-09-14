import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class PageEntry {
  PageEntry({
    required this.widget,
    required this.icon,
    required this.text,
  });
  final Widget widget;
  final Widget icon;
  final String text;
}

class PageState {
  PageState({required this.index, required this.showBadges});
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
  // `showBadges` is compared by value with listEquals, so it has to be hashed by
  // value too. Handing Object.hash a List folds in List.hashCode, which is
  // identity-based: two PageStates that compare equal but hold distinct list
  // instances would have disagreed on hashCode, breaking the contract that
  // equal objects hash equal. Object.hashAll folds the contents instead.
  int get hashCode => Object.hash(index, Object.hashAll(showBadges));
}

const int DENSITY_PAGE = 1;
const int OPTIONS_PAGE = 2;
