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
import '../../mocks/api_repository_mock.dart';

class MockFinsideService extends Mock implements FinsideApi {}

void main() {
  MockFinsideService finside;
  MockFirebaseAuth auth;
  MockApiRepository apiRepository;
  ApiBloc apiBloc;
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
    auth = MockFirebaseAuth(signedIn: true);
    apiRepository = MockApiRepository();
    apiBloc = ApiBloc(firebaseAuth: auth, apiRepository: apiRepository);
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
}
