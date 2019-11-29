import 'package:demo_api_app_flutter/blocs/bloc_provider.dart';
import 'dart:async';

class SelectPageBloc implements BlocBase {
  List<bool> _whichClicked = [false, false, false];
  StreamController<int> _pageController = StreamController<int>.broadcast();
  Stream<int> get outPageController => _pageController.stream;
  StreamSink get _inPageController => _pageController.sink;

  StreamController<List<bool>> _pageClickedController =
      StreamController<List<bool>>.broadcast();
  Stream<List<bool>> get outPageClickedController =>
      _pageClickedController.stream;
  StreamSink get _inPageClickedController => _pageClickedController.sink;

  SelectPageBloc() {
    _inPageController.add(0);
    _inPageClickedController.add(_whichClicked);
  }

  void setPage(int pageIndex) {
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
