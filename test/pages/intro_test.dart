import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/blocs/api/api_bloc.dart';
import 'package:realoptions/pages/intro.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import '../mocks/api_repository_mock.dart';

void main() {
  late MockFirebaseAuth auth;

  setUp(() {
    auth = MockFirebaseAuth();
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
          // Mirrors the app theme: `accentColor` is gone, the scheme's secondary
          // slot replaces it, and `bodyText2` is `bodyLarge`.
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.teal,
          ).copyWith(secondary: Colors.orange),
          buttonTheme: const ButtonThemeData(
            buttonColor: Colors.orange,
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(
              fontSize: 15.0,
            ),
          )),
    ));
    await tester.pumpAndSettle();
    // On the real clock: `await bloc.close()` never lands under testWidgets'
    // fake clock (see the note in density_test.dart).
    await tester.runAsync(bloc.close);
  });
}
