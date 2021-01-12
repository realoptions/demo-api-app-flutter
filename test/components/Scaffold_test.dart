import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:realoptions/blocs/constraints/constraints_bloc.dart';
import 'package:realoptions/blocs/constraints/constraints_events.dart';
import 'package:realoptions/blocs/select_page/select_page_bloc.dart';
import 'package:realoptions/services/finside_service.dart';
import 'package:realoptions/models/forms.dart';
import 'package:realoptions/models/response.dart';
import 'package:realoptions/components/AppScaffold.dart';
import 'package:realoptions/components/CustomTextFields.dart';

class MockFinsideService extends Mock implements FinsideApi {}

void main() {
  MockFinsideService finside;
  List<InputConstraint> constraints;
  setUp(() {
    finside = MockFinsideService();
    constraints = [
      InputConstraint(
          defaultValue: 2,
          upper: 3,
          lower: 1,
          fieldType: FieldType.Float,
          name: "asset",
          inputType: InputType.Market)
    ];
  });
  tearDown(() {
    finside = null;
    constraints = null;
  });
  void stubRetrieveData() {
    when(finside.fetchConstraints())
        .thenAnswer((_) => Future.value(constraints));
  }

  void stubRetrieveOptions() {
    when(finside.fetchOptionPrices(any)).thenAnswer((_) => Future.value({
          "call": [ModelResult(value: 4, atPoint: 4)],
          "put": [ModelResult(value: 4, atPoint: 4)]
        }));
  }

  void stubRetrieveDataWithError() {
    when(finside.fetchConstraints())
        .thenAnswer((_) => Future.error("Big error!"));
  }

  void stubRetrieveDensity() {
    var results = DensityAndVaR(
        density: [ModelResult(atPoint: 4, value: 3)],
        riskMetrics: VaRResult(valueAtRisk: 0.3, expectedShortfall: 0.4));
    when(finside.fetchDensityAndVaR(any))
        .thenAnswer((_) => Future.value(results));
  }

  testWidgets('Error if error is returned', (WidgetTester tester) async {
    stubRetrieveDataWithError();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BlocProvider<ConstraintsBloc>(
            create: (_) =>
                ConstraintsBloc(finside: finside)..add(RequestConstraints()),
            child: WaitForConstraints(
              title: "Hello",
              finside: finside,
              selectPageBloc: SelectPageBloc(),
            )),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text("Big error!"), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
  testWidgets('No error displayed if no error', (WidgetTester tester) async {
    stubRetrieveData();
    stubRetrieveOptions();
    stubRetrieveDensity();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BlocProvider<ConstraintsBloc>(
            create: (_) =>
                ConstraintsBloc(finside: finside)..add(RequestConstraints()),
            child: WaitForConstraints(
                title: "Hello",
                selectPageBloc: SelectPageBloc(),
                finside: finside)),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text("Big error!"), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text("Hello"), findsOneWidget);
  });
}
