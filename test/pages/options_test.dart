import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/pages/options.dart';
import 'package:realoptions/components/CustomPadding.dart';
import 'package:mockito/mockito.dart';
import 'package:realoptions/models/response.dart';

import 'package:realoptions/blocs/select_page/select_page_bloc.dart';
import 'package:realoptions/blocs/options/options_bloc.dart';

import '../mocks/finside_api_mock.dart';
import '../support/form_fixtures.dart';

void main() {
  late MockFinsideService finside;
  final OptionPrices results = OptionPrices(
    calls: [
      ModelResult(value: 4, atPoint: 4, iv: 0.3),
      ModelResult(value: 5, atPoint: 5, iv: 0.3)
    ],
    puts: [ModelResult(value: 4, atPoint: 4), ModelResult(value: 5, atPoint: 5)],
  );

  setUp(() {
    finside = MockFinsideService();
  });

  void stubRetrieveData() {
    when(finside.fetchOptionPrices(any))
        .thenAnswer((_) => Future.value(results));
  }

  void stubRetrieveDataWithError() {
    when(finside.fetchOptionPrices(any))
        .thenAnswer((_) => Future.error("Big error!"));
  }

  Widget wrap(OptionsBloc bloc) => MaterialApp(
        home: Directionality(
          child: BlocProvider<OptionsBloc>(
              create: (_) => bloc, child: ShowOptionPrices()),
          textDirection: TextDirection.ltr,
        ),
        theme: ThemeData(useMaterial3: false, colorSchemeSeed: Colors.teal),
      );

  /// Closes [bloc] on the real clock; see the note in `density_test.dart` —
  /// `await bloc.close()` never returns under `testWidgets`' fake clock.
  Future<void> closeBloc(WidgetTester tester, Bloc bloc) =>
      tester.runAsync(bloc.close);

  testWidgets('Options shows error if error', (WidgetTester tester) async {
    stubRetrieveDataWithError();
    final bloc = OptionsBloc(finside: finside, selectPageBloc: SelectPageBloc());
    await tester.pumpWidget(wrap(bloc));
    await tester.pumpAndSettle();
    expect(find.text("Please submit parameters!"), findsOneWidget);
    bloc.getOptions(hestonRequest());
    await tester.pumpAndSettle();
    expect(find.text("Big error!"), findsOneWidget);
    await closeBloc(tester, bloc);
  });

  testWidgets('Input no error or progress when data is returned',
      (WidgetTester tester) async {
    stubRetrieveData();
    final bloc = OptionsBloc(finside: finside, selectPageBloc: SelectPageBloc());
    await tester.pumpWidget(wrap(bloc));
    await tester.pumpAndSettle();
    expect(find.text("Big error!"), findsNothing);
    expect(find.text("Please submit parameters!"), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await closeBloc(tester, bloc);
  });

  testWidgets('Displays charts ratio when data is returned',
      (WidgetTester tester) async {
    stubRetrieveData();

    final bloc = OptionsBloc(finside: finside, selectPageBloc: SelectPageBloc());
    await tester.pumpWidget(wrap(bloc));
    await tester.pumpAndSettle();
    bloc.getOptions(hestonRequest());
    await tester.pumpAndSettle();
    expect(find.text("Please submit parameters!"), findsNothing);
    expect(find.byType(PaddingForm), findsNWidgets(2));
    await closeBloc(tester, bloc);
  });
}
