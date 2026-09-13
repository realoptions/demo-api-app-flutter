import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:realoptions/blocs/select_page/select_page_bloc.dart';
import 'package:realoptions/models/api_request.dart';
import 'package:realoptions/models/pages.dart';
import 'package:realoptions/models/response.dart';
import 'package:realoptions/services/finside_service.dart';
import 'package:realoptions/utils/request_guard.dart';

import 'density_events.dart';
import 'density_state.dart';

/// Fetches the density / VaR curve for a model.
///
/// Migrated from `mapEventToState` (removed in bloc 7) to the `on<E>`
/// registration API. The badge update on [SelectPageBloc] stays where it was:
/// it is a side effect on a sibling cubit, deliberately not modelled as part
/// of this bloc's own state stream, so the emitted sequence is unchanged.
class DensityBloc extends Bloc<DensityEvents, DensityState> {
  final FinsideApi finside;
  final SelectPageBloc selectPageBloc;

  /// Only the newest submit may publish. Two submits in a flight overlap
  /// (bloc 9 handles events concurrently), and the responses can come back in
  /// either order.
  final RequestGuard _guard = RequestGuard();

  DensityBloc({required this.finside, required this.selectPageBloc})
      : super(NoData()) {
    on<RequestDensity>(_onRequestDensity);
  }

  void getDensity(CalculationRequest request) {
    add(RequestDensity(request: request));
  }

  Future<void> _onRequestDensity(
    RequestDensity event,
    Emitter<DensityState> emit,
  ) async {
    final int request = _guard.begin();
    emit(IsDensityFetching());
    try {
      final DensityAndVaR result =
          await finside.fetchDensityAndVaR(event.request);
      // A newer submit superseded this one while it was in flight: publishing
      // its result (or its badge) would overwrite fresher data with stale data.
      if (!_guard.isCurrent(request)) return;
      selectPageBloc.setBadge(DENSITY_PAGE);
      emit(DensityData(density: result));
    } catch (err) {
      if (!_guard.isCurrent(request)) return;
      emit(DensityError(densityError: err.toString()));
    }
  }
}
