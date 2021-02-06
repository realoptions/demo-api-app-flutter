import 'package:bloc/bloc.dart';
import 'package:realoptions/blocs/select_page/select_page_bloc.dart';
import 'package:realoptions/models/pages.dart';
import 'dart:async';
import 'package:realoptions/services/finside_service.dart';
import 'package:meta/meta.dart';
import 'density_events.dart';
import 'density_state.dart';

class DensityBloc extends Bloc<DensityEvents, DensityState> {
  final FinsideApi finside;
  final SelectPageBloc selectPageBloc;
  DensityBloc({@required this.finside, @required this.selectPageBloc})
      : super(NoData());

  void getDensity(String model, Map<String, dynamic> body) {
    add(RequestDensity(model: model, body: body));
  }

  @override
  Stream<DensityState> mapEventToState(DensityEvents event) async* {
    if (event is RequestDensity) {
      yield IsDensityFetching();
      try {
        final result =
            await finside.fetchDensityAndVaR(event.model, event.body);
        selectPageBloc.setBadge(DENSITY_PAGE);
        yield DensityData(density: result);
      } catch (err) {
        yield DensityError(densityError: err.toString());
      }
    }
  }
}
