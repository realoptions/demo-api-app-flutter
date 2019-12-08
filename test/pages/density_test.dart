// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

///For some reason, I can't get these tests to pass
///The asyncronous streams make this awkward, but
///shouldn't make this impossible...

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/pages/density.dart';
import 'package:mockito/mockito.dart';
import 'package:realoptions/blocs/bloc_provider.dart';
import 'package:realoptions/blocs/density_bloc.dart';
import 'package:realoptions/services/finside_service.dart';
import 'package:realoptions/models/response.dart';
import 'package:realoptions/models/forms.dart';

class MockFinsideService extends Mock implements FinsideApi {}

void main() {
  MockFinsideService finside;
  List<ModelResult> results;
  Map<String, SubmitItems> body = {
    "asset": SubmitItems(value: 40.0, inputType: InputType.Market)
  };
  setUp(() {
    finside = MockFinsideService();
    results = [ModelResult(value: 4, atPoint: 4)];
  });
  tearDown(() {
    finside = null;
    results = null;
  });
  void stubRetrieveData() {
    when(finside.fetchModelDensity(any))
        .thenAnswer((_) => Future.value(results));
  }

  void stubRetrieveDataWithError() {
    when(finside.fetchModelDensity(any))
        .thenAnswer((_) => Future.error("Big error!"));
  }

  testWidgets('Density shows error if error', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    stubRetrieveDataWithError();
    var bloc = DensityBloc(finside: finside);
    await tester.pumpWidget(MaterialApp(
      home: Directionality(
        child: BlocProvider<DensityBloc>(bloc: bloc, child: ShowDensity()),
        textDirection: TextDirection.ltr,
      ),
      theme: ThemeData(
          primarySwatch: Colors.teal,
          accentColor: Colors.orange,
          buttonTheme: ButtonThemeData(
            buttonColor: Colors.orange,
          ),
          textTheme: TextTheme(
            body1: TextStyle(
              fontSize: 15.0,
            ),
          )),
    ));
    await tester.pumpAndSettle();
    expect(find.text("Please submit parameters!"), findsOneWidget);
    await bloc.getDensity(body);
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
      child: BlocProvider<DensityBloc>(
          bloc: DensityBloc(finside: finside), child: ShowDensity()),
      textDirection: TextDirection.ltr,
    )));
    await tester.pumpAndSettle();
    expect(find.text("Big error!"), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
