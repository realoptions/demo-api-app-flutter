import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/blocs/select_page/select_page_bloc.dart';
import 'package:realoptions/pages/density.dart';
import 'package:mockito/mockito.dart';
import 'package:realoptions/blocs/density/density_bloc.dart';
import 'package:realoptions/services/finside_service.dart';
import 'package:realoptions/models/response.dart';
import 'package:realoptions/models/forms.dart';
import 'package:realoptions/components/CustomPadding.dart';

class MockFinsideService extends Mock implements FinsideApi {}

void main() {
  MockFinsideService finside;
  DensityAndVaR results;
  setUp(() {
    finside = MockFinsideService();
    results = DensityAndVaR(
        density: [ModelResult(atPoint: 4, value: 3)],
        riskMetrics: VaRResult(valueAtRisk: 0.3, expectedShortfall: 0.4));
  });
  tearDown(() {
    finside = null;
    results = null;
  });
  void stubRetrieveData() {
    when(finside.fetchDensityAndVaR(any))
        .thenAnswer((_) => Future.value(results));
  }

  void stubRetrieveDataWithError() {
    when(finside.fetchDensityAndVaR(any))
        .thenAnswer((_) => Future.error("Big error!"));
  }

  /*testWidgets('Density shows progress', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    stubRetrieveDataWithError();
    var bloc = DensityBloc(finside: finside, selectPageBloc: SelectPageBloc());
    await tester.pumpWidget(MaterialApp(
      home: Directionality(
        child: BlocProvider<DensityBloc>(
            create: (_) => bloc, child: ShowDensity()),
        textDirection: TextDirection.ltr,
      ),
      theme: ThemeData(
          primarySwatch: Colors.teal,
          accentColor: Colors.orange,
          buttonTheme: ButtonThemeData(
            buttonColor: Colors.orange,
          ),
          textTheme: TextTheme(
            bodyText2: TextStyle(
              fontSize: 15.0,
            ),
          )),
    ));
    await tester.pumpAndSettle();
    expect(find.text("Please submit parameters!"), findsOneWidget);
    bloc.emit(IsDensityFetching());
    await tester.pump(); //AndSettle();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    bloc.close();
  });*/
  testWidgets('Density shows error if error', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    stubRetrieveDataWithError();
    var bloc = DensityBloc(finside: finside, selectPageBloc: SelectPageBloc());
    await tester.pumpWidget(MaterialApp(
      home: Directionality(
        child: BlocProvider<DensityBloc>(
            create: (_) => bloc, child: ShowDensity()),
        textDirection: TextDirection.ltr,
      ),
      theme: ThemeData(
          primarySwatch: Colors.teal,
          accentColor: Colors.orange,
          buttonTheme: ButtonThemeData(
            buttonColor: Colors.orange,
          ),
          textTheme: TextTheme(
            bodyText2: TextStyle(
              fontSize: 15.0,
            ),
          )),
    ));
    await tester.pumpAndSettle();
    expect(find.text("Please submit parameters!"), findsOneWidget);
    bloc.getDensity(
        {"asset": SubmitItems(value: 40.0, inputType: InputType.Market)});
    await tester.pumpAndSettle();
    expect(find.text("Big error!"), findsOneWidget);
    bloc.close();
  });
  testWidgets('Input no error or progress when data is returned',
      (WidgetTester tester) async {
    stubRetrieveData();
    await tester.pumpWidget(MaterialApp(
        home: Directionality(
      child: BlocProvider<DensityBloc>(
          create: (_) =>
              DensityBloc(finside: finside, selectPageBloc: SelectPageBloc()),
          child: ShowDensity()),
      textDirection: TextDirection.ltr,
    )));
    await tester.pumpAndSettle();
    expect(find.text("Big error!"), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
  testWidgets('Displays charts ratio when data is returned',
      (WidgetTester tester) async {
    stubRetrieveData();

    var bloc = DensityBloc(finside: finside, selectPageBloc: SelectPageBloc());
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body:
          BlocProvider<DensityBloc>(create: (_) => bloc, child: ShowDensity()),
    )));
    await tester.pumpAndSettle();

    bloc.getDensity(
        {"asset": SubmitItems(inputType: InputType.Market, value: 3.0)});
    await tester.pumpAndSettle();
    expect(find.text("Please submit parameters!"), findsNothing);
    expect(find.byType(PaddingForm), findsOneWidget);
    bloc.close();
  });
}
