import 'package:bloc/bloc.dart';
import 'package:realoptions/models/pages.dart';

class SelectPageBloc extends Cubit<PageState> {
  SelectPageBloc()
      : super(PageState(index: 0, showBadges: [false, false, false]));
  void setPage(int pageIndex) {
    final showBadges = state.showBadges.asMap().entries.map((entry) {
      return entry.key == pageIndex ? false : entry.value;
    }).toList();
    emit(PageState(index: pageIndex, showBadges: showBadges));
  }

  void setBadge(int pageIndex) {
    final showBadges = state.showBadges.asMap().entries.map((entry) {
      return entry.key == pageIndex ? true : entry.value;
    }).toList();
    emit(PageState(index: state.index, showBadges: showBadges));
  }
}
