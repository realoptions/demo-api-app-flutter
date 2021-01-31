import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/blocs/select_page/select_page_bloc.dart';
import 'package:realoptions/models/pages.dart';
import 'package:bloc_test/bloc_test.dart';

void main() {
  test('correct initial state', () {
    SelectPageBloc bloc = SelectPageBloc();
    expect(bloc.state, PageState(index: 0, showBadges: [false, false, false]));
  });
  blocTest('emits new page when updating index',
      build: () => SelectPageBloc(),
      act: (bloc) => bloc.setPage(1),
      expect: [
        PageState(index: 1, showBadges: [false, false, false])
      ]);
  blocTest('emits new badge when updating index',
      build: () => SelectPageBloc(),
      act: (bloc) => bloc.setBadge(1),
      expect: [
        PageState(index: 0, showBadges: [false, true, false])
      ]);
  blocTest('emits new page and then adjusts badge',
      build: () => SelectPageBloc(),
      act: (bloc) {
        bloc.setPage(1);
        bloc.setPage(0);
        bloc.setBadge(1);
        bloc.setPage(1);
      },
      expect: [
        PageState(index: 1, showBadges: [false, false, false]),
        PageState(index: 0, showBadges: [false, false, false]),
        PageState(index: 0, showBadges: [false, true, false]),
        PageState(index: 1, showBadges: [false, false, false])
      ]);
}
