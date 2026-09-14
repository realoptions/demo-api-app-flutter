import 'package:realoptions/blocs/api/api_bloc.dart';
import 'package:realoptions/components/CustomTextFields.dart';
import 'package:realoptions/models/forms.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/blocs/constraints/constraints_bloc.dart';
import 'package:realoptions/models/models.dart';
import 'package:mockito/mockito.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:realoptions/blocs/constraints/constraints_events.dart';
import 'package:realoptions/blocs/constraints/constraints_state.dart';

import '../mocks/finside_api_mock.dart';

// MockFinsideService comes from the shared test double, which supplies the typed
// `returnValue` placeholders a bare `extends Mock` cannot: `fetchConstraints`
// returns `Future<List<InputConstraint>>` and mockito's `noSuchMethod` hands
// back null during stub recording, which fails that cast.

/// `Cubit.close()` returns `Future<void>`, and a bare Mock's `noSuchMethod`
/// hands back `null` - which fails the implicit cast at the call site before
/// `when()` can even record the stub. Overriding with a real completed Future
/// keeps `tearDown` able to close it.
class MockApiBloc extends Mock implements ApiBloc {
  @override
  Future<void> close() => Future<void>.value();
}

void main() {
  // `late` because these are assigned in setUp, not at declaration: under sound
  // null safety a plain `MockFinsideService finside;` is non-nullable and the
  // analyser rightly refuses to read it before assignment.
  late MockFinsideService finside;
  late MockApiBloc apiBloc;
  List<InputConstraint> constraints = [
    InputConstraint(
        defaultValue: 2,
        upper: 3,
        lower: 1,
        fieldType: FieldType.Float,
        name: "somename",
        inputType: InputType.Market)
  ];
  setUp(() {
    finside = MockFinsideService();
    apiBloc = MockApiBloc();
  });
  tearDown(() {
    // No `finside.close()`: the shared mock sets `throwOnMissingStub`, so an
    // unstubbed `close()` would raise, and the mock owns no resources anyway.
    apiBloc.close();
  });

  test('gets correct initial state', () async {
    final bloc = ConstraintsBloc(finside: finside, apiBloc: apiBloc);
    expect(bloc.state, ConstraintsIsFetching());
    bloc.close();
  });
  blocTest(
    'emits [data] when RequestConstraints is added',
    build: () {
      when(finside.fetchConstraints("heston"))
          .thenAnswer((_) => Future.value(constraints));
      return ConstraintsBloc(finside: finside, apiBloc: apiBloc);
    },
    act: (bloc) => bloc.add(
        RequestConstraints(model: Model(label: "Heston", value: "heston"))),
    expect: () => [
      ConstraintsIsFetching(),
      ConstraintsData(constraints: constraints)
    ],
  );
  blocTest(
    'emits [error] when error is returned',
    build: () {
      when(finside.fetchConstraints("heston"))
          .thenAnswer((_) => Future.error("Some Error"));
      return ConstraintsBloc(finside: finside, apiBloc: apiBloc);
    },
    act: (bloc) => bloc.add(
        RequestConstraints(model: Model(label: "Heston", value: "heston"))),
    expect: () => [
      ConstraintsIsFetching(),
      ConstraintsError(constraintsError: "Some Error")
    ],
  );
  blocTest('emits ConstraintsFetching when JWT expires',
      build: () {
        when(finside.fetchConstraints("heston"))
            .thenAnswer((_) => Future.error("Exception: Jwt is expired"));
        return ConstraintsBloc(finside: finside, apiBloc: apiBloc);
      },
      act: (bloc) => bloc.add(
          RequestConstraints(model: Model(label: "Heston", value: "heston"))),
      expect: () => [ConstraintsIsFetching()],
      verify: (_) {
        verify(apiBloc.setNoData()).called(1);
      });
}
