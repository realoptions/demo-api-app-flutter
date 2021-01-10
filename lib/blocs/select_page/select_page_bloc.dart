import 'package:realoptions/blocs/bloc_provider.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:realoptions/models/pages.dart';

///Since _pageState is mutated and the stream returns a reference
///to the _pageState object, any changes to the _pageState are reflected
///in the history of the stream.  This doesn't matter for this application,
///but is behavior to be aware of.  For an example of how this is unintuitive,
///see the unit tests for this bloc
class SelectPageBloc implements BlocBase {
  PageState _pageState = PageState(index: 0, showBadges: [false, false, false]);
  final StreamController<PageState> _pageController = BehaviorSubject();
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
