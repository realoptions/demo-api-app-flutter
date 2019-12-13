import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/blocs/bloc_provider.dart';
import 'package:realoptions/blocs/select_model_bloc.dart';
import 'package:realoptions/components/OptionsAppBar.dart';
import 'package:mockito/mockito.dart';
import 'package:realoptions/services/persistant_storage_service.dart';
import 'package:realoptions/blocs/api_bloc.dart';

class MockPersistentStorage extends Mock implements PersistentStorage {}

void main() {
  MockPersistentStorage apiStorage;

  setUp(() {
    apiStorage = MockPersistentStorage();
  });
  tearDown(() {
    apiStorage = null;
  });
  void stubRetrieveData() {
    String key = "somekey";
    when(apiStorage.retrieveValue(any)).thenAnswer((_) => Future.value(key));
  }

  void stubInsertKey() {
    when(apiStorage.insertValue(any, any)).thenAnswer((_) => Future.value());
  }

  testWidgets('AppBar displays with no inputs', (WidgetTester tester) async {
    stubRetrieveData();
    await tester.pumpWidget(MaterialApp(
        home: Material(
            child: BlocProvider<ApiBloc>(
                bloc: ApiBloc(apiStorage: apiStorage),
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
                bloc: ApiBloc(apiStorage: apiStorage),
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
                bloc: ApiBloc(apiStorage: apiStorage),
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
                bloc: ApiBloc(apiStorage: apiStorage),
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
