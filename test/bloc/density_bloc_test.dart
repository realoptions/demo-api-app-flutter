import 'package:realoptions/blocs/select_page/select_page_bloc.dart';
import 'package:realoptions/models/forms.dart';
import 'package:realoptions/models/response.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/blocs/density/density_bloc.dart';
import 'package:realoptions/services/finside_service.dart';
import 'package:mockito/mockito.dart';
import 'package:realoptions/blocs/density/density_state.dart';
import 'package:realoptions/blocs/density/density_events.dart';
import 'package:bloc_test/bloc_test.dart';

class MockFinsideService extends Mock implements FinsideApi {}

void main() {
  MockFinsideService finside;
  DensityAndVaR results = DensityAndVaR(
      density: [ModelResult(atPoint: 4, value: 3)],
      riskMetrics: VaRResult(valueAtRisk: 0.3, expectedShortfall: 0.4));
  DensityBloc bloc;
  Map<String, SubmitItems> body = {
    "asset": SubmitItems(inputType: InputType.Market, value: 5.0)
  };
  setUp(() {
    finside = MockFinsideService();
    when(finside.fetchDensityAndVaR(any))
        .thenAnswer((_) => Future.value(results));
    bloc = DensityBloc(finside: finside, selectPageBloc: SelectPageBloc());
  });
  tearDown(() {
    finside = null;
    bloc.close();
  });

  test('gets correct initial state', () {
    expect(bloc.state, NoData());
  });
  blocTest(
    'emits [data] when RequestDensity is added',
    build: () => bloc,
    act: (bloc) => bloc.add(RequestDensity(body: body)),
    expect: [IsDensityFetching(), DensityData(density: results)],
  );
  blocTest(
    'emits [error] when error is returned',
    build: () {
      when(finside.fetchDensityAndVaR(any))
          .thenAnswer((_) => Future.error("Some Error"));
      return bloc;
    },
    act: (bloc) => bloc.add(RequestDensity(body: body)),
    expect: [IsDensityFetching(), DensityError(densityError: "Some Error")],
  );
}
