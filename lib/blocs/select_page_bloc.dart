import 'package:demo_api_app_flutter/blocs/bloc_provider.dart';
import 'dart:async';

class SelectPageBloc implements BlocBase {
  List<bool> _whichClicked = [false, false, false];
  StreamController<int> _pageController = StreamController<int>();
  Stream<int> get outPageController => _pageController.stream;
  StreamSink get _inPageController => _pageController.sink;

  StreamController<List<bool>> _pageClickedController =
      StreamController<List<bool>>();
  Stream<List<bool>> get outPageClickedController =>
      _pageClickedController.stream;
  StreamSink get _inPageClickedController => _pageClickedController.sink;

  StreamController _actionController = StreamController();
  StreamSink get setPageIndex => _actionController.sink;

  SelectPageBloc() {
    _actionController.stream.listen(_setPage);
    _inPageController.add(0);
    _inPageClickedController.add(_whichClicked);
  }

  void _setPage(int pageIndex) {
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
    _actionController.close();
    _pageClickedController.close();
  }
}
