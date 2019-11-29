import 'package:demo_api_app_flutter/blocs/bloc_provider.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';

class SelectPageBloc implements BlocBase {
  List<bool> _whichClicked = [false, false, false];
  StreamController<int> _pageController = BehaviorSubject();
  Stream<int> get outPageController => _pageController.stream;
  StreamSink get _inPageController => _pageController.sink;

  StreamController<List<bool>> _pageClickedController = BehaviorSubject();
  Stream<List<bool>> get outPageClickedController =>
      _pageClickedController.stream;
  StreamSink get _inPageClickedController => _pageClickedController.sink;

  SelectPageBloc() {
    print("at create page bloc");
    _inPageController.add(0);
    _inPageClickedController.add(_whichClicked);
  }

  void setPage(int pageIndex) {
    print("page index");
    print(pageIndex);
    _whichClicked[pageIndex] = false;
    _inPageController.add(pageIndex);
    _inPageClickedController.add(_whichClicked);
  }

  void setAllNotClicked() {
    _whichClicked = [true, true, true];
    _inPageClickedController.add(_whichClicked);
  }

  void dispose() {
    _pageController.close();
    _pageClickedController.close();
  }
}
