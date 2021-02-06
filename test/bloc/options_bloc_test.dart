import 'package:realoptions/models/forms.dart';
import 'package:realoptions/models/response.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/services/finside_service.dart';
import 'package:mockito/mockito.dart';
import 'package:realoptions/blocs/options/options_bloc.dart';
import 'package:realoptions/blocs/options/options_state.dart';
import 'package:realoptions/blocs/options/options_events.dart';
import 'package:realoptions/blocs/select_page/select_page_bloc.dart';
import 'package:bloc_test/bloc_test.dart';

class MockFinsideService extends Mock implements FinsideApi {}

void main() {
  MockFinsideService finside;
  OptionsBloc bloc;
  Map<String, List<ModelResult>> results = {
    "call": [ModelResult(atPoint: 4, value: 3)]
  };
  Map<String, SubmitItems> body = {
    "asset": SubmitItems(inputType: InputType.Market, value: 5.0)
  };
  setUp(() {
    finside = MockFinsideService();
    when(finside.fetchOptionPrices(any, any))
        .thenAnswer((_) => Future.value(results));
    bloc = OptionsBloc(finside: finside, selectPageBloc: SelectPageBloc());
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
    act: (bloc) => bloc.add(RequestOptions(body: body, model: "heston")),
    expect: [IsOptionsFetching(), OptionsData(options: results)],
  );
  blocTest(
    'emits [error] when error is returned',
    build: () {
      when(finside.fetchOptionPrices(any, any))
          .thenAnswer((_) => Future.error("Some Error"));
      return bloc;
    },
    act: (bloc) => bloc.add(RequestOptions(body: body, model: "heston")),
    expect: [IsOptionsFetching(), OptionsError(optionsError: "Some Error")],
  );
}
