import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/blocs/select_page/select_page_bloc.dart';
import 'package:realoptions/pages/density.dart';
import 'package:mockito/mockito.dart';
import 'package:realoptions/blocs/density/density_bloc.dart';
import 'package:realoptions/models/response.dart';
import 'package:realoptions/components/CustomPadding.dart';

import '../mocks/finside_api_mock.dart';
import '../support/form_fixtures.dart';

void main() {
  late MockFinsideService finside;
  final DensityAndVaR results = DensityAndVaR(
      density: [ModelResult(atPoint: 4, value: 3)],
      riskMetrics: VaRResult(valueAtRisk: 0.3, expectedShortfall: 0.4));

  setUp(() {
    finside = MockFinsideService();
  });

  void stubRetrieveData() {
    when(finside.fetchDensityAndVaR(any))
        .thenAnswer((_) => Future.value(results));
  }

  void stubRetrieveDataWithError() {
    when(finside.fetchDensityAndVaR(any))
        .thenAnswer((_) => Future.error("Big error!"));
  }

  Widget wrap(DensityBloc bloc) => MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: BlocProvider<DensityBloc>(
              create: (_) => bloc, child: ShowDensity()),
        ),
        theme: ThemeData(useMaterial3: false, colorSchemeSeed: Colors.teal),
      );

  /// Closes [bloc] for real.
  ///
  /// `testWidgets` runs on a fake clock, and the broadcast `StreamController`
  /// that backs a bloc only lands its `done` future on a real event loop: with
  /// the fake clock, `await bloc.close()` never returns and the test times out
  /// (the bloc itself is marked closed synchronously, but the await hangs).
  /// `runAsync` runs the close on the real clock, so the future completes and
  /// the teardown is actually awaited rather than skipped.
  Future<void> closeBloc(WidgetTester tester, Bloc bloc) =>
      tester.runAsync(bloc.close);

  testWidgets('Density shows parameter message', (WidgetTester tester) async {
    stubRetrieveDataWithError();
    final bloc =
        DensityBloc(finside: finside, selectPageBloc: SelectPageBloc());
    await tester.pumpWidget(wrap(bloc));
    await tester.pumpAndSettle();
    expect(find.text("Please submit parameters!"), findsOneWidget);
    await closeBloc(tester, bloc);
  });

  testWidgets('Density shows error if error', (WidgetTester tester) async {
    stubRetrieveDataWithError();
    final bloc =
        DensityBloc(finside: finside, selectPageBloc: SelectPageBloc());
    await tester.pumpWidget(wrap(bloc));
    await tester.pumpAndSettle();
    expect(find.text("Please submit parameters!"), findsOneWidget);
    bloc.getDensity(hestonRequest());
    await tester.pumpAndSettle();
    expect(find.text("Big error!"), findsOneWidget);
    await closeBloc(tester, bloc);
  });

  testWidgets('Input no error or progress when data is returned',
      (WidgetTester tester) async {
    stubRetrieveData();
    final bloc =
        DensityBloc(finside: finside, selectPageBloc: SelectPageBloc());
    await tester.pumpWidget(wrap(bloc));
    await tester.pumpAndSettle();
    expect(find.text("Big error!"), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await closeBloc(tester, bloc);
  });

  testWidgets('Displays charts ratio when data is returned',
      (WidgetTester tester) async {
    stubRetrieveData();

    final bloc =
        DensityBloc(finside: finside, selectPageBloc: SelectPageBloc());
    await tester.pumpWidget(wrap(bloc));
    await tester.pumpAndSettle();

    bloc.getDensity(hestonRequest());
    await tester.pumpAndSettle();
    expect(find.text("Please submit parameters!"), findsNothing);
    expect(find.byType(PaddingForm), findsOneWidget);
    await closeBloc(tester, bloc);
  });
}
