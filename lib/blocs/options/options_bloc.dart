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

  void getOptions(String model, Map<String, dynamic> body) {
    add(RequestOptions(model: model, body: body));
  }

  @override
  Stream<OptionsState> mapEventToState(OptionsEvents event) async* {
    if (event is RequestOptions) {
      yield IsOptionsFetching();
      try {
        final result = await finside.fetchOptionPrices(event.model, event.body);
        selectPageBloc.setBadge(OPTIONS_PAGE);
        yield OptionsData(options: result);
      } catch (err) {
        yield OptionsError(optionsError: err.toString());
      }
    }
  }
}
