import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:realoptions/blocs/api/api_bloc.dart';
import 'package:realoptions/models/forms.dart';
import 'package:realoptions/models/models.dart';
import 'package:realoptions/services/finside_service.dart';
import 'package:realoptions/utils/request_guard.dart';

import 'constraints_events.dart';
import 'constraints_state.dart';

/// Fetches the parameter ranges (constraints) for a model.
///
/// Migrated from `mapEventToState` (removed in bloc 7) to the `on<E>`
/// registration API. The events here are classes rather than an enum, so each
/// one gets its own registered handler.
class ConstraintsBloc extends Bloc<ConstraintsEvents, ConstraintsState> {
  final FinsideApi finside;
  final ApiBloc apiBloc;

  /// Only the newest model switch may publish. Switching the model in the app
  /// bar twice in quick succession leaves two requests in flight, and the
  /// slower one must not replace the constraints of the model that is now
  /// selected.
  final RequestGuard _guard = RequestGuard();

  ConstraintsBloc({required this.finside, required this.apiBloc})
      : super(ConstraintsIsFetching()) {
    on<RequestConstraints>(_onRequestConstraints);
  }

  void getConstraints(Model model) {
    add(RequestConstraints(model: model));
  }

  Future<void> _onRequestConstraints(
    RequestConstraints event,
    Emitter<ConstraintsState> emit,
  ) async {
    final int request = _guard.begin();
    emit(ConstraintsIsFetching());
    try {
      final List<InputConstraint> result =
          await finside.fetchConstraints(event.model.value);
      if (!_guard.isCurrent(request)) return;
      emit(ConstraintsData(constraints: result));
    } catch (err) {
      // A superseded request's error is as stale as its result would have
      // been, and here it is worse than merely stale: the JWT branch below
      // signs the session out, so a late error from a model the user has
      // already switched away from would tear down a session that the newer
      // request was happily using.
      if (!_guard.isCurrent(request)) return;
      final String strError = err.toString();
      if (strError == "Exception: Jwt is expired") {
        // Ask ApiBloc for a fresh token. Handled inline rather than by emitting
        // a "please refresh" state: from this bloc's point of view a stale JWT
        // is not a user-facing error, it is a retry condition owned by
        // ApiBloc, so the state we settle on is still "fetching" exactly as
        // before.
        apiBloc.setNoData();
        emit(ConstraintsIsFetching());
      } else {
        emit(ConstraintsError(constraintsError: strError));
      }
    }
  }
}
