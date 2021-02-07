import 'package:bloc/bloc.dart';
import 'package:realoptions/blocs/api/api_bloc.dart';
import 'package:realoptions/models/models.dart';
import 'dart:async';
import 'package:realoptions/services/finside_service.dart';
import 'package:meta/meta.dart';
import 'constraints_events.dart';
import 'constraints_state.dart';

class ConstraintsBloc extends Bloc<ConstraintsEvents, ConstraintsState> {
  final FinsideApi finside;
  final ApiBloc apiBloc;
  ConstraintsBloc({@required this.finside, @required this.apiBloc})
      : super(ConstraintsIsFetching());
  void getConstraints(Model model) {
    add(RequestConstraints(model: model));
  }

  @override
  Stream<ConstraintsState> mapEventToState(ConstraintsEvents event) async* {
    print(event);
    if (event is RequestConstraints) {
      yield ConstraintsIsFetching();
      try {
        final result = await finside.fetchConstraints(event.model.value);
        yield ConstraintsData(constraints: result);
      } catch (err) {
        final strError = err.toString();
        if (strError == "Exception: Jwt is expired") {
          apiBloc.setNoData();
          yield ConstraintsIsFetching();
        } else {
          yield ConstraintsError(constraintsError: strError);
        }
      }
    }
  }
}
