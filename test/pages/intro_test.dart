import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:realoptions/blocs/bloc_provider.dart';
import 'package:realoptions/blocs/api_bloc.dart';
import 'package:realoptions/pages/intro.dart';

import 'package:realoptions/services/persistant_storage_service.dart';

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
    when(apiStorage.insertValue(any, any))
        .thenAnswer((_) => Future.value("hello"));
  }

  testWidgets('Updates api key on change', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    stubInsertKey();
    stubRetrieveData();
    var bloc = ApiBloc(apiStorage: apiStorage);
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
