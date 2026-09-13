import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:realoptions/blocs/select_page/select_page_bloc.dart';
import 'package:realoptions/models/api_request.dart';
import 'package:realoptions/models/pages.dart';
import 'package:realoptions/models/response.dart';
import 'package:realoptions/services/finside_service.dart';
import 'package:realoptions/utils/request_guard.dart';

import 'options_events.dart';
import 'options_state.dart';

/// Fetches call and put option prices for a model.
///
/// Migrated from `mapEventToState` (removed in bloc 7) to the `on<E>`
/// registration API. As in [DensityBloc], the badge update on [SelectPageBloc]
/// is a side effect on a sibling cubit and stays out of this bloc's own state
/// stream, so the emitted sequence is unchanged.
class OptionsBloc extends Bloc<OptionsEvents, OptionsState> {
  final FinsideApi finside;
  final SelectPageBloc selectPageBloc;

  /// Only the newest submit may publish. One submit is already two HTTP calls
  /// (call + put); two overlapping submits are four, and they settle in
  /// whatever order the network returns them.
  final RequestGuard _guard = RequestGuard();

  OptionsBloc({required this.finside, required this.selectPageBloc})
      : super(NoData()) {
    on<RequestOptions>(_onRequestOptions);
  }

  void getOptions(CalculationRequest request) {
    add(RequestOptions(request: request));
  }

  Future<void> _onRequestOptions(
    RequestOptions event,
    Emitter<OptionsState> emit,
  ) async {
    final int request = _guard.begin();
    emit(IsOptionsFetching());
    try {
      final OptionPrices result =
          await finside.fetchOptionPrices(event.request);
      // Superseded by a newer submit: drop the whole call/put pair rather than
      // painting prices for parameters the user has already replaced.
      if (!_guard.isCurrent(request)) return;
      selectPageBloc.setBadge(OPTIONS_PAGE);
      emit(OptionsData(options: result));
    } catch (err) {
      if (!_guard.isCurrent(request)) return;
      emit(OptionsError(optionsError: err.toString()));
    }
  }
}
