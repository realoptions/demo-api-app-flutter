import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/blocs/api/api_bloc.dart';
import 'package:realoptions/blocs/constraints/constraints_events.dart';
import 'package:realoptions/blocs/options/options_bloc.dart';
import 'package:realoptions/blocs/select_model/select_model_bloc.dart';
import 'package:realoptions/models/models.dart';
import 'package:realoptions/pages/form.dart';
import 'package:mockito/mockito.dart';
import 'package:realoptions/blocs/constraints/constraints_bloc.dart';
import 'package:realoptions/blocs/form/form_bloc.dart';
import 'package:realoptions/blocs/density/density_bloc.dart';
import 'package:realoptions/blocs/select_page/select_page_bloc.dart';
import 'package:realoptions/services/finside_service.dart';
import 'package:realoptions/models/forms.dart';
import 'package:realoptions/models/response.dart';
import 'package:realoptions/components/CustomTextFields.dart';
import '../../mocks/api_repository_mock.dart';

class MockFinsideService extends Mock implements FinsideApi {}

void main() {
  MockFinsideService finside;
  List<InputConstraint> constraints;
  MockFirebaseAuth auth;
  MockApiRepository apiRepository;
  ApiBloc apiBloc;
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
    auth = MockFirebaseAuth(signedIn: true);
    apiRepository = MockApiRepository();
    apiBloc = ApiBloc(firebaseAuth: auth, apiRepository: apiRepository);
  });
  tearDown(() {
    finside = null;
    constraints = null;
    apiBloc.close();
  });
  void stubRetrieveData() {
    when(finside.fetchConstraints("heston"))
        .thenAnswer((_) => Future.value(constraints));
  }

  void stubRetrieveOptions() {
    when(finside.fetchOptionPrices(any, any)).thenAnswer((_) => Future.value({
          "call": [ModelResult(value: 4, atPoint: 4)],
          "put": [ModelResult(value: 4, atPoint: 4)]
        }));
  }

  void stubRetrieveDensity() {
    var results = DensityAndVaR(
        density: [ModelResult(atPoint: 4, value: 3)],
        riskMetrics: VaRResult(valueAtRisk: 0.3, expectedShortfall: 0.4));
    when(finside.fetchDensityAndVaR(any, any))
        .thenAnswer((_) => Future.value(results));
  }

  testWidgets('Input no error or progress when data is returned',
      (WidgetTester tester) async {
    stubRetrieveData();
    final bloc = SelectPageBloc();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Directionality(
                textDirection: TextDirection.ltr,
                child: MultiBlocProvider(
                    providers: [
                      BlocProvider<ConstraintsBloc>(create: (context) {
                        return ConstraintsBloc(
                            finside: finside, apiBloc: apiBloc)
                          ..add(RequestConstraints(
                              model: Model(label: "Heston", value: "heston")));
                      }),
                      BlocProvider<SelectPageBloc>(create: (context) {
                        return bloc;
                      }),
                      BlocProvider<SelectModelBloc>(create: (context) {
                        return SelectModelBloc();
                      }),
                    ],
                    child: MultiBlocProvider(providers: [
                      BlocProvider<DensityBloc>(
                          create: (context) => DensityBloc(
                              finside: finside, selectPageBloc: bloc)),
                      BlocProvider<OptionsBloc>(
                          create: (context) => OptionsBloc(
                              finside: finside, selectPageBloc: bloc)),
                      BlocProvider<FormBloc>(
                          create: (context) =>
                              FormBloc(constraints: constraints))
                    ], child: InputForm()))))));
    await tester.pumpAndSettle();
    expect(find.text("Big error!"), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
  testWidgets('submits form', (WidgetTester tester) async {
    stubRetrieveData();
    stubRetrieveOptions();
    stubRetrieveDensity();
    var bloc = FormBloc(constraints: constraints);
    //final selectPageBloc = SelectPageBloc();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Directionality(
                textDirection: TextDirection.ltr,
                child: MultiBlocProvider(
                    providers: [
                      BlocProvider<ConstraintsBloc>(create: (context) {
                        return ConstraintsBloc(
                            finside: finside, apiBloc: apiBloc)
                          ..add(RequestConstraints(
                              model: Model(label: "Heston", value: "heston")));
                      }),
                      BlocProvider<SelectPageBloc>(create: (context) {
                        return SelectPageBloc();
                      }),
                      BlocProvider<SelectModelBloc>(create: (context) {
                        return SelectModelBloc();
                      }),
                    ],
                    child: MultiBlocProvider(providers: [
                      BlocProvider<DensityBloc>(
                          create: (context) => DensityBloc(
                              finside: finside,
                              selectPageBloc: context.read<SelectPageBloc>())),
                      BlocProvider<OptionsBloc>(
                          create: (context) => OptionsBloc(
                              finside: finside,
                              selectPageBloc: context.read<SelectPageBloc>())),
                      BlocProvider<FormBloc>(create: (context) => bloc)
                    ], child: InputForm()))))));
    await tester.pumpAndSettle();
    expect(find.text("Big error!"), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.enterText(find.byType(TextFormField), "2.5");
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(find.text("Big error!"), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(bloc.getCurrentForm(),
        {"asset": SubmitItems(value: 2.5, inputType: InputType.Market)});
  });
}
