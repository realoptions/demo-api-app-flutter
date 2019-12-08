// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

///For some reason, I can't get these tests to pass
///The asyncronous streams make this awkward, but
///shouldn't make this impossible...

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:realoptions/blocs/bloc_provider.dart';
import 'package:realoptions/blocs/options_bloc.dart';
import 'package:realoptions/models/api_key.dart';
import 'package:realoptions/blocs/api_bloc.dart';
import 'package:realoptions/pages/intro.dart';

import 'package:realoptions/services/api_key_service.dart';

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
    when(db.insertKey(any)).thenAnswer((_) => Future.value("hello"));
  }

  testWidgets('Updates api key on change', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    stubInsertKey();
    stubRetrieveData();
    var bloc = ApiBloc(db: db);
    await tester.pumpWidget(MaterialApp(
      home: Directionality(
        child: BlocProvider<ApiBloc>(bloc: bloc, child: Introduction()),
        textDirection: TextDirection.ltr,
      ),
      theme: ThemeData(
          primarySwatch: Colors.teal,
          accentColor: Colors.orange,
          buttonTheme: ButtonThemeData(
            buttonColor: Colors.orange,
          ),
          textTheme: TextTheme(
            body1: TextStyle(
              fontSize: 15.0,
            ),
          )),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(Key("textdescription")), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), "hello");
    expect(bloc.getApiKey(), "hello");
    await tester.tap(find.byType(RaisedButton));
    await tester.pumpAndSettle();
  });
}
