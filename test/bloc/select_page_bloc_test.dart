import 'package:flutter_test/flutter_test.dart';
import 'package:demo_api_app_flutter/blocs/select_page_bloc.dart';
import 'package:demo_api_app_flutter/models/pages.dart';

void main() {
  test('emits first page on instantiation', () {
    SelectPageBloc bloc = SelectPageBloc();
    expect(
        bloc.outPageController,
        emitsInOrder([
          PageState(index: 0, showBadges: [false, false, false])
        ]));
  });
  test('emits new page when updating index', () {
    SelectPageBloc bloc = SelectPageBloc();
    expect(
        bloc.outPageController,
        emitsInOrder([
          PageState(index: 1, showBadges: [
            false,
            false,
            false
          ]), //since _pageState is a reference, the initial value is updated
          PageState(index: 1, showBadges: [false, false, false]),
        ]));
    bloc.setPage(1);
  });
  test('emits update to badge when badge set', () {
    SelectPageBloc bloc = SelectPageBloc();

    expect(
        bloc.outPageController,
        emitsInOrder([
          PageState(index: 0, showBadges: [
            false,
            true,
            false
          ]), //since _pageState is a reference, the initial value is updated
          PageState(index: 0, showBadges: [false, true, false]),
        ]));
    bloc.setBadge(1);
  });
  test('emits update to badge when badge set and then removes badge', () {
    SelectPageBloc bloc = SelectPageBloc();
    expect(
        bloc.outPageController,
        emitsInOrder([
          PageState(index: 1, showBadges: [
            false,
            false,
            false
          ]), //since _pageState is a reference, the initial value is updated
          PageState(index: 1, showBadges: [
            false,
            false,
            false
          ]), //since _pageState is a reference, the initial value is updated
          PageState(index: 1, showBadges: [false, false, false]),
        ]));
    bloc.setBadge(1);
    bloc.setPage(1);
  });
}
