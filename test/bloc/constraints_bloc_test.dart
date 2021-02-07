import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:realoptions/blocs/api/api_bloc.dart';
import 'package:realoptions/components/CustomTextFields.dart';
import 'package:realoptions/models/forms.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/blocs/constraints/constraints_bloc.dart';
import 'package:realoptions/models/models.dart';
import 'package:realoptions/services/finside_service.dart';
import 'package:mockito/mockito.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:realoptions/blocs/constraints/constraints_events.dart';
import 'package:realoptions/blocs/constraints/constraints_state.dart';

class MockFinsideService extends Mock implements FinsideApi {}

class MockApiBloc extends Mock implements ApiBloc {}

void main() {
  MockFinsideService finside;
  MockApiBloc apiBloc;
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
    finside = null;
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
    expect: [
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
    expect: [
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
      expect: [ConstraintsIsFetching()],
      verify: (_) {
        verify(apiBloc.setNoData()).called(1);
      });
}
