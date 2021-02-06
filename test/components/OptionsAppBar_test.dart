import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/blocs/api/api_bloc.dart';
import 'package:realoptions/blocs/constraints/constraints_bloc.dart';
import 'package:realoptions/blocs/select_model/select_model_bloc.dart';
import 'package:realoptions/components/OptionsAppBar.dart';
import 'package:realoptions/models/models.dart';
import '../../mocks/api_repository_mock.dart';
import 'Scaffold_test.dart';

void main() {
  MockFinsideService finside;
  MockFirebaseAuth auth;
  MockApiRepository apiRepository;
  ApiBloc apiBloc;
  setUp(() {
    finside = MockFinsideService();
    auth = MockFirebaseAuth(signedIn: true);
    apiRepository = MockApiRepository();
    apiBloc = ApiBloc(firebaseAuth: auth, apiRepository: apiRepository);
  });
  tearDown(() {
    finside = null;
    apiBloc.close();
  });
  testWidgets('AppBar displays with no inputs', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Material(
          child: MultiBlocProvider(
              providers: [
            BlocProvider<ConstraintsBloc>(
                create: (context) =>
                    ConstraintsBloc(finside: finside, apiBloc: apiBloc)),
            BlocProvider<SelectModelBloc>(
              create: (context) => SelectModelBloc(),
            )
          ],
              child: Scaffold(
                  appBar: OptionsAppBar(
                      choices: MODEL_CHOICES, title: "SomeTitle")))),
    ));
    await tester.pumpAndSettle();
    expect(find.text("SomeTitle: Heston"), findsOneWidget);
    expect(find.text("SomeTitle: CGMY"), findsNothing);
  });
  testWidgets('AppBar selection works', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Material(
            child: MultiBlocProvider(
                providers: [
          BlocProvider<ConstraintsBloc>(
              create: (context) =>
                  ConstraintsBloc(finside: finside, apiBloc: apiBloc)),
          BlocProvider<SelectModelBloc>(
            create: (context) => SelectModelBloc(),
          )
        ],
                child: Scaffold(
                    appBar: OptionsAppBar(
                        choices: MODEL_CHOICES, title: "SomeTitle"))))));
    await tester.pumpAndSettle();
    expect(find.text("SomeTitle: Heston"), findsOneWidget);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text("CGMY"), findsOneWidget);
    await tester.tap(find.text("CGMY"));
    await tester.pumpAndSettle();
    expect(find.text("SomeTitle: CGMY"), findsOneWidget);
    expect(find.text("CGMY"), findsNothing);
  });
}
