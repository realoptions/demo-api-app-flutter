import 'package:demo_api_app_flutter/blocs/bloc_provider.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:demo_api_app_flutter/models/pages.dart';

class SelectPageBloc implements BlocBase {
  PageState _pageState = PageState(index: 0, showBadges: [false, false, false]);
  StreamController<PageState> _pageController = BehaviorSubject();
  Stream<PageState> get outPageController => _pageController.stream;
  StreamSink get _inPageController => _pageController.sink;

  SelectPageBloc() {
    _inPageController.add(_pageState);
  }

  void setPage(int pageIndex) {
    _pageState.showBadges[pageIndex] = false;
    _pageState.index = pageIndex;
    _inPageController.add(_pageState);
  }

  void setBadge(int pageIndex) {
    _pageState.showBadges[pageIndex] = true;
    _inPageController.add(_pageState);
  }

  void dispose() {
    _pageController.close();
  }
}
