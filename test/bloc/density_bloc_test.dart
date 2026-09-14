import 'package:realoptions/blocs/select_page/select_page_bloc.dart';
import 'package:realoptions/models/api_request.dart';
import 'package:realoptions/models/response.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/blocs/density/density_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:realoptions/blocs/density/density_state.dart';
import 'package:realoptions/blocs/density/density_events.dart';
import 'package:bloc_test/bloc_test.dart';

import '../mocks/finside_api_mock.dart';
import '../support/form_fixtures.dart';

void main() {
  late MockFinsideService finside;
  final DensityAndVaR results = DensityAndVaR(
      density: [ModelResult(atPoint: 4, value: 3)],
      riskMetrics: VaRResult(valueAtRisk: 0.3, expectedShortfall: 0.4));
  late DensityBloc bloc;
  late CalculationRequest request;

  setUp(() {
    finside = MockFinsideService();
    request = hestonRequest();
    when(finside.fetchDensityAndVaR(any))
        .thenAnswer((_) => Future.value(results));
    bloc = DensityBloc(finside: finside, selectPageBloc: SelectPageBloc());
  });

  tearDown(() async {
    await bloc.close();
  });

  test('gets correct initial state', () {
    expect(bloc.state, NoData());
  });

  blocTest<DensityBloc, DensityState>(
    'emits [data] when RequestDensity is added',
    build: () => bloc,
    act: (bloc) => bloc.add(RequestDensity(request: request)),
    expect: () => [IsDensityFetching(), DensityData(density: results)],
  );

  blocTest<DensityBloc, DensityState>(
    'hands the typed request to the service untouched',
    build: () => bloc,
    act: (bloc) => bloc.getDensity(request),
    expect: () => [IsDensityFetching(), DensityData(density: results)],
    verify: (_) {
      // Stubbed with `any`, verified against the exact object: the bloc must
      // forward the very request it was given, not a re-built stand-in.
      verify(finside.fetchDensityAndVaR(request)).called(1);
    },
  );

  blocTest<DensityBloc, DensityState>(
    'emits [error] when error is returned',
    build: () {
      when(finside.fetchDensityAndVaR(any))
          .thenAnswer((_) => Future.error("Some Error"));
      return bloc;
    },
    act: (bloc) => bloc.add(RequestDensity(request: request)),
    expect: () =>
        [IsDensityFetching(), DensityError(densityError: "Some Error")],
  );
}
