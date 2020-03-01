import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/pages/options.dart';
import 'package:realoptions/components/CustomPadding.dart';
import 'package:mockito/mockito.dart';
import 'package:realoptions/blocs/bloc_provider.dart';
import 'package:realoptions/blocs/options_bloc.dart';
import 'package:realoptions/services/finside_service.dart';
import 'package:realoptions/models/response.dart';
import 'package:realoptions/models/forms.dart';

class MockFinsideService extends Mock implements FinsideApi {}

void main() {
  MockFinsideService finside;
  Map<String, List<ModelResult>> results;
  Map<String, SubmitItems> body = {
    "asset": SubmitItems(value: 40.0, inputType: InputType.Market)
  };
  setUp(() {
    finside = MockFinsideService();
    results = {
      "call": [
        ModelResult(value: 4, atPoint: 4, iv: 0.3),
        ModelResult(value: 5, atPoint: 5, iv: 0.3)
      ],
      "put": [
        ModelResult(value: 4, atPoint: 4),
        ModelResult(value: 5, atPoint: 5)
      ]
    };
  });
  tearDown(() {
    finside = null;
    results = null;
  });
  void stubRetrieveData() {
    when(finside.fetchOptionPrices(any))
        .thenAnswer((_) => Future.value(results));
  }

  void stubRetrieveDataWithError() {
    when(finside.fetchOptionPrices(any))
        .thenAnswer((_) => Future.error("Big error!"));
  }

  testWidgets('Density shows error if error', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    stubRetrieveDataWithError();
    var bloc = OptionsBloc(finside: finside);
    await tester.pumpWidget(MaterialApp(
      home: Directionality(
        child: BlocProvider<OptionsBloc>(bloc: bloc, child: ShowOptionPrices()),
        textDirection: TextDirection.ltr,
      ),
      theme: ThemeData(
          primarySwatch: Colors.teal,
          accentColor: Colors.orange,
          buttonTheme: ButtonThemeData(
            buttonColor: Colors.orange,
          ),
          textTheme: TextTheme(
            bodyText1: TextStyle(
              fontSize: 15.0,
            ),
          )),
    ));
    await tester.pumpAndSettle();
    expect(find.text("Please submit parameters!"), findsOneWidget);
    await bloc.getOptionPrices(body);
    await tester.pump(Duration.zero);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text("Big error!"), findsOneWidget);
  });
  testWidgets('Input no error or progress when data is returned',
      (WidgetTester tester) async {
    stubRetrieveData();
    await tester.pumpWidget(MaterialApp(
        home: Directionality(
      child: BlocProvider<OptionsBloc>(
          bloc: OptionsBloc(finside: finside), child: ShowOptionPrices()),
      textDirection: TextDirection.ltr,
    )));
    await tester.pumpAndSettle();
    expect(find.text("Big error!"), findsNothing);
    expect(find.text("Please submit parameters!"), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
  testWidgets('Displays charts ratio when data is returned',
      (WidgetTester tester) async {
    stubRetrieveData();

    var bloc = OptionsBloc(finside: finside);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: BlocProvider<OptionsBloc>(bloc: bloc, child: ShowOptionPrices()),
    )));
    await tester.pumpAndSettle();
    await bloc.getOptionPrices(
        {"asset": SubmitItems(inputType: InputType.Market, value: 3.0)});
    await tester.pumpAndSettle();
    expect(find.text("Please submit parameters!"), findsNothing);
    expect(find.byType(PaddingForm), findsNWidgets(2));
  });
}
