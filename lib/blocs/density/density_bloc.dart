import 'package:bloc/bloc.dart';
import 'package:realoptions/blocs/select_page/select_page_bloc.dart';
import 'package:realoptions/models/forms.dart';
import 'package:realoptions/models/pages.dart';
import 'dart:async';
import 'package:realoptions/services/finside_service.dart';
import 'package:meta/meta.dart';
import 'density_events.dart';
import 'density_state.dart';
//import '../select_page/select_page_bloc.dart';

class DensityBloc extends Bloc<DensityEvents, DensityState> {
  final FinsideApi finside;
  final SelectPageBloc selectPageBloc;
  DensityBloc({@required this.finside, @required this.selectPageBloc})
      : super(NoData());

  void getDensity(Map<String, SubmitItems> body) {
    add(RequestDensity(body: body));
  }

  @override
  Stream<DensityState> mapEventToState(DensityEvents event) async* {
    if (event is RequestDensity) {
      yield IsDensityFetching();
      try {
        final result = await finside.fetchDensityAndVaR(event.body);
        yield DensityData(density: result);
        selectPageBloc.setBadge(DENSITY_PAGE);
      } catch (err) {
        yield DensityError(densityError: err);
      }
    }
  }
}
