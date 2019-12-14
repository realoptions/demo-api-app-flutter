import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/pages/form.dart';
import 'package:mockito/mockito.dart';
import 'package:realoptions/blocs/bloc_provider.dart';
import 'package:realoptions/blocs/constraints_bloc.dart';
import 'package:realoptions/blocs/form_bloc.dart';
import 'package:realoptions/blocs/options_bloc.dart';
import 'package:realoptions/blocs/density_bloc.dart';
import 'package:realoptions/blocs/select_page_bloc.dart';
import 'package:realoptions/services/finside_service.dart';
import 'package:realoptions/models/forms.dart';
import 'package:realoptions/models/response.dart';
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

  void stubRetrieveDensity() {
    var results = DensityAndVaR(
        density: [ModelResult(atPoint: 4, value: 3)],
        riskMetrics: VaRResult(valueAtRisk: 0.3, expectedShortfall: 0.4));
    when(finside.fetchDensityAndVaR(any))
        .thenAnswer((_) => Future.value(results));
  }

  testWidgets('Input no error or progress when data is returned',
      (WidgetTester tester) async {
    stubRetrieveData();
    //var bloc = ConstraintsBloc(finside: finside);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Directionality(
      child: BlocProvider<FormBloc>(
        child: BlocProvider<DensityBloc>(
          child: BlocProvider<OptionsBloc>(
            child: BlocProvider<SelectPageBloc>(
              child: BlocProvider<ConstraintsBloc>(
                  bloc: ConstraintsBloc(finside: finside), child: InputForm()),
              bloc: SelectPageBloc(),
            ),
            bloc: OptionsBloc(finside: finside),
          ),
          bloc: DensityBloc(finside: finside),
        ),
        bloc: FormBloc(constraints: constraints),
      ),
      textDirection: TextDirection.ltr,
    ))));
    await tester.pumpAndSettle();
    expect(find.text("Big error!"), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
  testWidgets('submits form', (WidgetTester tester) async {
    stubRetrieveData();
    stubRetrieveOptions();
    stubRetrieveDensity();
    var bloc = FormBloc(constraints: constraints);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Directionality(
      child: BlocProvider<ConstraintsBloc>(
        child: BlocProvider<DensityBloc>(
          child: BlocProvider<OptionsBloc>(
            child: BlocProvider<SelectPageBloc>(
              child: BlocProvider<FormBloc>(bloc: bloc, child: InputForm()),
              bloc: SelectPageBloc(),
            ),
            bloc: OptionsBloc(finside: finside),
          ),
          bloc: DensityBloc(finside: finside),
        ),
        bloc: ConstraintsBloc(finside: finside),
      ),
      textDirection: TextDirection.ltr,
    ))));
    await tester.pumpAndSettle();
    expect(find.text("Big error!"), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.enterText(find.byType(TextFormField), "2.5");
    await tester.pumpAndSettle();
    await tester.tap(find.byType(RaisedButton));
    await tester.pumpAndSettle();
    expect(find.text("Big error!"), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(bloc.getCurrentForm(),
        {"asset": SubmitItems(value: 2.5, inputType: InputType.Market)});
  });
}
