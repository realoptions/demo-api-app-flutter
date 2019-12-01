import 'package:demo_api_app_flutter/models/api_key.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
//import "dart:async";
import 'package:demo_api_app_flutter/blocs/api_bloc.dart';
import 'package:demo_api_app_flutter/services/api_key_service.dart';
import 'package:demo_api_app_flutter/models/progress.dart';

class MockApiDB extends Mock implements ApiDB {}

void main() {
  MockApiDB db;
  setUp(() {
    // used to provide environment variables for my test
    //buildTestEnvironment();
    db = MockApiDB();
  });
  test('starts with empty apiKey', () {
    ApiBloc bloc = ApiBloc();
    expect(bloc.getApiKey(), "");
  });
  test('executes progress in correct order', () {
    List<ApiKey> keys = [ApiKey(id: 1, key: "somekey")];
    ApiBloc bloc = MockApiBloc();
    when(bloc.db).thenReturn(MockApiDB());
    when(bloc.db.retrieveKey()).thenAnswer((_) => Future.value(keys));
    //expect(bloc.outHomeState,
    //emitsInOrder([StreamProgress.Busy, StreamProgress.DataRetrieved]));
    bloc.setApiKey("Hello");

    expect(bloc.getApiKey(), "Hello");
    bloc.saveApiKey();
    expect(bloc.outApiKey, emitsInOrder(["hello"]));
  });

  /*testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });*/
}
