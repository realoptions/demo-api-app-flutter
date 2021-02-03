import 'package:bloc/bloc.dart';
import 'package:realoptions/models/pages.dart';
import 'dart:async';
import 'package:realoptions/services/finside_service.dart';
import 'package:meta/meta.dart';
import 'options_events.dart';
import 'options_state.dart';
import 'package:realoptions/blocs/select_page/select_page_bloc.dart';

class OptionsBloc extends Bloc<OptionsEvents, OptionsState> {
  final FinsideApi finside;
  final SelectPageBloc selectPageBloc;
  OptionsBloc({@required this.finside, @required this.selectPageBloc})
      : super(NoData());

  void getOptions(Map<String, dynamic> body) {
    add(RequestOptions(body: body));
  }

  @override
  Stream<OptionsState> mapEventToState(OptionsEvents event) async* {
    if (event is RequestOptions) {
      yield IsOptionsFetching();
      try {
        final result = await finside.fetchOptionPrices(event.body);
        yield OptionsData(options: result);
        selectPageBloc.setBadge(OPTIONS_PAGE);
      } catch (err) {
        yield OptionsError(optionsError: err.toString());
      }
    }
  }
}
