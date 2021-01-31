import 'package:realoptions/components/CustomTextFields.dart';
import 'package:realoptions/models/forms.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/blocs/constraints/constraints_bloc.dart';
import 'package:realoptions/services/finside_service.dart';
import 'package:mockito/mockito.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:realoptions/blocs/constraints/constraints_events.dart';
import 'package:realoptions/blocs/constraints/constraints_state.dart';

class MockFinsideService extends Mock implements FinsideApi {}

void main() {
  MockFinsideService finside;
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
  });
  tearDown(() {
    finside = null;
  });

  test('gets correct initial state', () async {
    final bloc = ConstraintsBloc(finside: finside);
    expect(bloc.state, ConstraintsIsFetching());
    bloc.close();
  });
  blocTest(
    'emits [data] when RequestConstraints is added',
    build: () {
      when(finside.fetchConstraints())
          .thenAnswer((_) => Future.value(constraints));
      return ConstraintsBloc(finside: finside);
    },
    act: (bloc) => bloc.add(RequestConstraints()),
    expect: [
      ConstraintsIsFetching(),
      ConstraintsData(constraints: constraints)
    ],
  );
  blocTest(
    'emits [error] when error is returned',
    build: () {
      when(finside.fetchConstraints())
          .thenAnswer((_) => Future.error("Some Error"));
      return ConstraintsBloc(finside: finside);
    },
    act: (bloc) => bloc.add(RequestConstraints()),
    expect: [
      ConstraintsIsFetching(),
      ConstraintsError(constraintsError: "Some Error")
    ],
  );
}
