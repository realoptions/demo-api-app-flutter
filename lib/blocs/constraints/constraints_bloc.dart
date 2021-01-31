import 'package:bloc/bloc.dart';
import 'dart:async';
import 'package:realoptions/services/finside_service.dart';
import 'package:meta/meta.dart';
import 'constraints_events.dart';
import 'constraints_state.dart';

class ConstraintsBloc extends Bloc<ConstraintsEvents, ConstraintsState> {
  final FinsideApi finside;
  ConstraintsBloc({@required this.finside}) : super(ConstraintsIsFetching());

  @override
  Stream<ConstraintsState> mapEventToState(ConstraintsEvents event) async* {
    if (event is RequestConstraints) {
      yield ConstraintsIsFetching();
      try {
        final result = await finside.fetchConstraints();
        yield ConstraintsData(constraints: result);
      } catch (err) {
        yield ConstraintsError(constraintsError: err.toString());
      }
    }
  }
}
