import 'package:realoptions/models/forms.dart';
import 'package:realoptions/models/response.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/blocs/density_bloc.dart';
import 'package:realoptions/models/progress.dart';
import 'package:realoptions/services/finside_service.dart';
import 'package:mockito/mockito.dart';

class MockFinsideService extends Mock implements FinsideApi {}

void main() {
  MockFinsideService finside;
  List<ModelResult> results;
  setUp(() {
    finside = MockFinsideService();
    results = [ModelResult(atPoint: 4, value: 3)];
  });
  tearDown(() {
    finside = null;
  });
  void stubRetrieveData() {
    when(finside.fetchModelDensity(any))
        .thenAnswer((_) => Future.value(results));
  }

  test('gets correct progress updates', () {
    stubRetrieveData();
    DensityBloc bloc = DensityBloc(finside: finside);
    Map<String, SubmitItems> body = {
      "asset": SubmitItems(inputType: InputType.Market, value: 5.0)
    };
    expect(
        bloc.outDensityProgress,
        emitsInOrder([
          StreamProgress.NoData,
          StreamProgress.Busy,
          StreamProgress.DataRetrieved
        ]));
    bloc.getDensity(body);
  });
  test('gets results', () {
    stubRetrieveData();
    DensityBloc bloc = DensityBloc(finside: finside);
    Map<String, SubmitItems> body = {
      "asset": SubmitItems(inputType: InputType.Market, value: 5.0)
    };
    expect(bloc.outDensityController, emitsInOrder([results]));
    bloc.getDensity(body);
  });
}
