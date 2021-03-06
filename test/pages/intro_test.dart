import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/blocs/api/api_bloc.dart';
import 'package:realoptions/pages/intro.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import '../../mocks/api_repository_mock.dart';

void main() {
  MockFirebaseAuth auth;

  setUp(() {
    auth = MockFirebaseAuth();
  });
  tearDown(() {
    auth = null;
  });

  testWidgets('Updates api key on change', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    var bloc = ApiBloc(firebaseAuth: auth, apiRepository: MockApiRepository());
    await tester.pumpWidget(MaterialApp(
      home: Directionality(
        child:
            BlocProvider<ApiBloc>(create: (_) => bloc, child: Introduction()),
        textDirection: TextDirection.ltr,
      ),
      theme: ThemeData(
          primarySwatch: Colors.teal,
          accentColor: Colors.orange,
          buttonTheme: ButtonThemeData(
            buttonColor: Colors.orange,
          ),
          textTheme: TextTheme(
            bodyText2: TextStyle(
              fontSize: 15.0,
            ),
          )),
    ));
    await tester.pumpAndSettle();
    bloc.close();
  });
}
