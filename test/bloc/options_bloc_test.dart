import 'package:demo_api_app_flutter/models/forms.dart';
import 'package:demo_api_app_flutter/models/response.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_api_app_flutter/blocs/options_bloc.dart';
import 'package:demo_api_app_flutter/models/progress.dart';
import 'package:demo_api_app_flutter/services/finside_service.dart';
import 'package:mockito/mockito.dart';

class MockFinsideService extends Mock implements FinsideApi {}

void main() {
  MockFinsideService finside;
  Map<String, List<ModelResult>> results;
  setUp(() {
    finside = MockFinsideService();
    results = {
      "call": [ModelResult(atPoint: 4, value: 3)]
    };
  });
  tearDown(() {
    finside = null;
  });
  void stubRetrieveData() {
    when(finside.fetchOptionPrices(any))
        .thenAnswer((_) => Future.value(results));
  }

  test('gets correct progress updates', () {
    stubRetrieveData();
    OptionsBloc bloc = OptionsBloc(finside: finside);
    Map<String, SubmitItems> body = {
      "asset": SubmitItems(inputType: InputType.Market, value: 5.0)
    };
    expect(
        bloc.outOptionsProgress,
        emitsInOrder([
          StreamProgress.NoData,
          StreamProgress.Busy,
          StreamProgress.DataRetrieved
        ]));
    bloc.getOptionPrices(body);
  });
  test('gets results', () {
    stubRetrieveData();
    OptionsBloc bloc = OptionsBloc(finside: finside);
    Map<String, SubmitItems> body = {
      "asset": SubmitItems(inputType: InputType.Market, value: 5.0)
    };
    expect(bloc.outOptionResults, emitsInOrder([results]));
    bloc.getOptionPrices(body);
  });
}
