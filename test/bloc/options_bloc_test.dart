import 'package:realoptions/models/api_request.dart';
import 'package:realoptions/models/response.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:realoptions/blocs/options/options_bloc.dart';
import 'package:realoptions/blocs/options/options_state.dart';
import 'package:realoptions/blocs/options/options_events.dart';
import 'package:realoptions/blocs/select_page/select_page_bloc.dart';
import 'package:bloc_test/bloc_test.dart';

import '../mocks/finside_api_mock.dart';
import '../support/form_fixtures.dart';

void main() {
  late MockFinsideService finside;
  late OptionsBloc bloc;
  final OptionPrices results = OptionPrices(
    calls: [ModelResult(atPoint: 4, value: 3, iv: 0.3)],
    puts: [ModelResult(atPoint: 4, value: 1)],
  );
  late CalculationRequest request;

  setUp(() {
    finside = MockFinsideService();
    request = hestonRequest();
    when(finside.fetchOptionPrices(any))
        .thenAnswer((_) => Future.value(results));
    bloc = OptionsBloc(finside: finside, selectPageBloc: SelectPageBloc());
  });

  tearDown(() async {
    await bloc.close();
  });

  test('gets correct initial state', () {
    expect(bloc.state, OptionsNoData());
  });

  blocTest<OptionsBloc, OptionsState>(
    'emits [data] when RequestOptions is added',
    build: () => bloc,
    act: (bloc) => bloc.add(RequestOptions(request: request)),
    expect: () => [IsOptionsFetching(), OptionsData(options: results)],
  );

  blocTest<OptionsBloc, OptionsState>(
    'hands the typed request to the service untouched',
    build: () => bloc,
    act: (bloc) => bloc.getOptions(request),
    expect: () => [IsOptionsFetching(), OptionsData(options: results)],
    verify: (_) {
      // Stubbed with `any`, verified against the exact object: the bloc must
      // forward the very request it was given, not a re-built stand-in.
      verify(finside.fetchOptionPrices(request)).called(1);
    },
  );

  blocTest<OptionsBloc, OptionsState>(
    'emits [error] when error is returned',
    build: () {
      when(finside.fetchOptionPrices(any))
          .thenAnswer((_) => Future.error("Some Error"));
      return bloc;
    },
    act: (bloc) => bloc.add(RequestOptions(request: request)),
    expect: () =>
        [IsOptionsFetching(), OptionsError(optionsError: "Some Error")],
  );
}
