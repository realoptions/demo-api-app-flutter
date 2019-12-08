import 'package:realoptions/components/CustomTextFields.dart';
import 'package:realoptions/models/forms.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/blocs/constraints_bloc.dart';
import 'package:realoptions/models/progress.dart';
import 'package:realoptions/services/finside_service.dart';
import 'package:mockito/mockito.dart';

class MockFinsideService extends Mock implements FinsideApi {}

void main() {
  MockFinsideService finside;
  List<InputConstraint> constraints;
  setUp(() {
    finside = MockFinsideService();
    constraints = [
      InputConstraint(
          defaultValue: 2,
          upper: 3,
          lower: 1,
          fieldType: FieldType.Float,
          name: "somename",
          inputType: InputType.Market)
    ];
  });
  tearDown(() {
    finside = null;
    constraints = null;
  });
  void stubRetrieveData() {
    when(finside.fetchConstraints())
        .thenAnswer((_) => Future.value(constraints));
  }

  test('gets correct progress updates', () {
    stubRetrieveData();
    ConstraintsBloc bloc = ConstraintsBloc(finside: finside);
    expect(bloc.outConstraintsProgress,
        emitsInOrder([StreamProgress.Busy, StreamProgress.DataRetrieved]));
  });
  test('gets results', () {
    stubRetrieveData();
    ConstraintsBloc bloc = ConstraintsBloc(finside: finside);
    expect(bloc.outConstraintsController, emitsInOrder([constraints]));
  });
}
