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
import 'package:realoptions/models/forms.dart';
import 'package:realoptions/models/response.dart';
import '../mocks/api_repository_mock.dart';
import '../mocks/finside_api_mock.dart';
import '../support/form_fixtures.dart';

void main() {
  late MockFinsideService finside;
  late List<InputConstraint> constraints;
  late MockFirebaseAuth auth;
  late MockApiRepository apiRepository;
  late ApiBloc apiBloc;
  setUp(() {
    finside = MockFinsideService();
    // The whole Heston parameter set. Submitting builds a typed request, which
    // needs every market and model field present, so a one-field form can no
    // longer stand in for a real submission.
    constraints = fullHestonConstraints();
    auth = MockFirebaseAuth(signedIn: true);
    apiRepository = MockApiRepository();
    apiBloc = ApiBloc(firebaseAuth: auth, apiRepository: apiRepository);
  });
  tearDown(() {
    apiBloc.close();
  });
  void stubRetrieveData() {
    when(finside.fetchConstraints("heston"))
        .thenAnswer((_) => Future.value(constraints));
  }

  void stubRetrieveOptions() {
    when(finside.fetchOptionPrices(any)).thenAnswer((_) => Future.value(
        OptionPrices(
            calls: [ModelResult(value: 4, atPoint: 4)],
            puts: [ModelResult(value: 4, atPoint: 4)])));
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
    await tester.enterText(find.byType(TextFormField).first, "2.5");
    await tester.pumpAndSettle();
    // Ten fields push the submit button below the fold of the scrolling form,
    // so a bare tap() hits nothing; scroll it into view first.
    final Finder submit = find.text('Submit');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text("Big error!"), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    // Saving the form writes every rendered field, not only the edited one, so
    // the assertion is on the field that was changed rather than on the whole
    // map.
    expect(bloc.getCurrentForm()["asset"],
        SubmitItems(value: 2.5, inputType: InputType.Market));
    verify(finside.fetchOptionPrices(any)).called(1);
    verify(finside.fetchDensityAndVaR(any)).called(1);
  });
}
