import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/pages/form.dart';
import 'package:realoptions/blocs/bloc_provider.dart';
import 'package:realoptions/blocs/select_model_bloc.dart';
import 'package:realoptions/components/OptionsAppBar.dart';
import 'package:mockito/mockito.dart';
import 'package:realoptions/services/api_key_service.dart';
import 'package:realoptions/blocs/api_bloc.dart';
import 'package:realoptions/models/api_key.dart';

class MockApiDB extends Mock implements ApiDB {}

void main() {
  MockApiDB db;

  setUp(() {
    db = MockApiDB();
  });
  tearDown(() {
    db = null;
  });
  void stubRetrieveData() {
    ApiKey key = ApiKey(id: 1, key: "somekey");
    when(db.retrieveKey()).thenAnswer((_) => Future.value([key]));
  }

  void stubInsertKey() {
    when(db.insertKey(any)).thenAnswer((_) => Future.value());
  }

  testWidgets('AppBar displays with no inputs', (WidgetTester tester) async {
    stubRetrieveData();
    await tester.pumpWidget(MaterialApp(
        home: Material(
            child: BlocProvider<ApiBloc>(
                bloc: ApiBloc(db: db),
                child: BlocProvider<SelectModelBloc>(
                    bloc: SelectModelBloc(),
                    child: Scaffold(
                        appBar: OptionsAppBar(
                            choices: modelChoices, title: "SomeTitle")))))));
    await tester.pumpAndSettle();
    expect(find.text("SomeTitle: Heston"), findsOneWidget);
    expect(find.text("SomeTitle: CGMY"), findsNothing);
  });
  testWidgets('AppBar selection works', (WidgetTester tester) async {
    stubRetrieveData();
    await tester.pumpWidget(MaterialApp(
        home: Material(
            child: BlocProvider<ApiBloc>(
                bloc: ApiBloc(db: db),
                child: BlocProvider<SelectModelBloc>(
                    bloc: SelectModelBloc(),
                    child: Scaffold(
                        appBar: OptionsAppBar(
                            choices: modelChoices, title: "SomeTitle")))))));
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
  testWidgets('AppBar api key works', (WidgetTester tester) async {
    stubRetrieveData();
    await tester.pumpWidget(MaterialApp(
        home: Material(
            child: BlocProvider<ApiBloc>(
                bloc: ApiBloc(db: db),
                child: BlocProvider<SelectModelBloc>(
                    bloc: SelectModelBloc(),
                    child: Scaffold(
                        appBar: OptionsAppBar(
                            choices: modelChoices, title: "SomeTitle")))))));
    await tester.pumpAndSettle();
    expect(find.text("SomeTitle: Heston"), findsOneWidget);
    await tester.tap(find.byIcon(Icons.lock));
    await tester.pumpAndSettle();
    expect(find.text("somekey"), findsOneWidget); //apikey
    expect(find.text("CANCEL"), findsOneWidget);
    await tester.tap(find.text("CANCEL"));
    await tester.pumpAndSettle();
    expect(find.text("CANCEL"), findsNothing);
  });
  testWidgets('AppBar api key works when changing',
      (WidgetTester tester) async {
    stubRetrieveData();
    stubInsertKey();
    await tester.pumpWidget(MaterialApp(
        home: Material(
            child: BlocProvider<ApiBloc>(
                bloc: ApiBloc(db: db),
                child: BlocProvider<SelectModelBloc>(
                    bloc: SelectModelBloc(),
                    child: Scaffold(
                        appBar: OptionsAppBar(
                            choices: modelChoices, title: "SomeTitle")))))));
    await tester.pumpAndSettle();
    expect(find.text("SomeTitle: Heston"), findsOneWidget);
    await tester.tap(find.byIcon(Icons.lock));
    await tester.pumpAndSettle();
    expect(find.text("somekey"), findsOneWidget); //apikey
    expect(find.text("CANCEL"), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), "new api key");
    await tester.tap(find.text("SAVE"));
    await tester.pumpAndSettle();
    expect(find.text("CANCEL"), findsNothing);
    await tester.tap(find.byIcon(Icons.lock));
    await tester.pumpAndSettle();
    expect(find.text("new api key"), findsOneWidget); //new apikey
  });
}
