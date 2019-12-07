// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:demo_api_app_flutter/models/forms.dart';
import 'package:demo_api_app_flutter/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_api_app_flutter/services/api_key_service.dart';
import 'package:demo_api_app_flutter/main.dart';
import 'package:demo_api_app_flutter/services/finside_service.dart';
import 'package:demo_api_app_flutter/models/response.dart';
import 'package:mockito/mockito.dart';
import 'package:demo_api_app_flutter/components/CustomTextFields.dart';
import 'package:demo_api_app_flutter/models/api_key.dart';

class MockApiDB extends Mock implements ApiDB {}

class MockFinsideService extends Mock implements FinsideApi {}

void main() {
  MockFinsideService finside;
  MockApiDB db;
  List<ModelResult> resultsDensity;
  Map<String, List<ModelResult>> resultsOptions;
  List<InputConstraint> constraints;
  setUp(() {
    finside = MockFinsideService();
    db = MockApiDB();
    resultsDensity = [ModelResult(atPoint: 4, value: 3)];
    resultsOptions = {
      "call": [ModelResult(atPoint: 4, value: 3)],
      "put": [ModelResult(atPoint: 4, value: 3)]
    };
    constraints = [
      InputConstraint(
          defaultValue: 2,
          upper: 3,
          lower: 1,
          type: FieldType.Float,
          name: "somename",
          inputType: InputType.Market)
    ];
  });
  tearDown(() {
    finside = null;
  });
  void stubDensityData() {
    when(finside.fetchModelDensity(any))
        .thenAnswer((_) => Future.value(resultsDensity));
  }

  void stubOptionsData() {
    when(finside.fetchOptionPrices(any))
        .thenAnswer((_) => Future.value(resultsOptions));
  }

  void stubConstraints() {
    when(finside.fetchConstraints())
        .thenAnswer((_) => Future.value(constraints));
  }

  void stubRetrieveApi() {
    ApiKey key = ApiKey(id: 1, key: "somekey");
    when(db.retrieveKey()).thenAnswer((_) => Future.value([key]));
  }

  void stubRetrieveNoApi() {
    when(db.retrieveKey()).thenAnswer((_) => Future.value([]));
  }

  void stubInsertKey() {
    when(db.insertKey(any)).thenAnswer((_) => Future.value());
  }

  void stubRemoveKey() {
    when(db.removeKey(any)).thenAnswer((_) => Future.value());
  }

  testWidgets('Works to change options', (WidgetTester tester) async {
    stubDensityData();
    stubOptionsData();
    stubConstraints();
    stubRetrieveApi();
    final Type radioListTileType = const RadioListTile<String>(
      value: "MyValue1", //these are irrelavant
      groupValue: "MyValue1", //these are irrelavant
      onChanged: null,
    ).runtimeType;
    List<RadioListTile<String>> generatedRadioListTiles;
    List<RadioListTile<String>> findTiles() => find
        .byType(radioListTileType)
        .evaluate()
        .map<RadioListTile<String>>((Element element) => element.widget)
        .toList();
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(db: db));

    // Verify that our title starts with.
    expect(find.text('Options: Heston'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pump();
    generatedRadioListTiles = findTiles();
    expect(generatedRadioListTiles[0].checked, equals(true));
    expect(generatedRadioListTiles[1].checked, equals(false));
    await tester.tap(find.text("CGMY"));
    await tester.pump();
    expect(find.text('Options: CGMY'), findsOneWidget);
  });
}
