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

  /// Pumps [Introduction] under the app theme with a live [ApiBloc].
  ///
  /// The bloc is returned rather than closed here because `bloc.close()` does not
  /// land under `testWidgets`' fake clock — it has to run on the real clock via
  /// `tester.runAsync`, which is only reachable from inside the test body (see
  /// the note in density_test.dart).
  Future<ApiBloc> pumpSignIn(WidgetTester tester, {String? errorMessage}) async {
    final ApiBloc bloc =
        ApiBloc(firebaseAuth: auth, apiRepository: MockApiRepository());
    await tester.pumpWidget(MaterialApp(
      home: Directionality(
        textDirection: TextDirection.ltr,
        child: BlocProvider<ApiBloc>(
            create: (_) => bloc, child: Introduction(errorMessage: errorMessage)),
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
    return bloc;
  }

  testWidgets('Updates api key on change', (WidgetTester tester) async {
    final ApiBloc bloc = await pumpSignIn(tester);
    // On the real clock: `await bloc.close()` never lands under testWidgets'
    // fake clock (see the note in density_test.dart).
    await tester.runAsync(bloc.close);
  });

  testWidgets('Google is the only way in', (WidgetTester tester) async {
    final ApiBloc bloc = await pumpSignIn(tester);

    expect(find.byKey(const Key("google")), findsOneWidget);
    expect(find.text("Sign in with Google"), findsOneWidget);

    // Facebook is not a provider any more (no app id existed for the web build)
    // and neither is anonymous access (the hosting project does not allow it).
    // Asserted as absent so neither can come back as a button nobody wired up.
    expect(find.text("Sign in with Facebook"), findsNothing);
    expect(find.text("Continue as guest"), findsNothing);

    await tester.runAsync(bloc.close);
  });

  testWidgets('a failed sign-in puts the reason on the screen',
      (WidgetTester tester) async {
    const String reason =
        'Sign-in failed: A network error occurred (network-request-failed)';
    final ApiBloc bloc = await pumpSignIn(tester, errorMessage: reason);

    // The reason has to be on the screen itself. It used to be logged only, and
    // a released web build has no listener for that log, so a failed sign-in
    // looked exactly like a button nobody had pressed.
    expect(find.byKey(const Key("signInError")), findsOneWidget);
    expect(find.text(reason), findsOneWidget);

    await tester.runAsync(bloc.close);
  });

  testWidgets('no failure text on a clean sign-in screen',
      (WidgetTester tester) async {
    final ApiBloc bloc = await pumpSignIn(tester);

    expect(find.byKey(const Key("signInError")), findsNothing);

    await tester.runAsync(bloc.close);
  });
}
