import 'package:realoptions/blocs/api/api_events.dart';
import 'package:realoptions/blocs/api/api_state.dart';
import 'package:flutter/material.dart';
import 'package:realoptions/components/AppScaffold.dart';
import 'package:realoptions/blocs/select_model/select_model_bloc.dart';
import 'package:realoptions/blocs/api/api_bloc.dart';
import 'package:realoptions/pages/intro.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realoptions/repositories/api_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:realoptions/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Web options come from the build environment (see FirebaseConfig); off the web
  // they are null so the native SDK reads its own google-services.json.
  if (kIsWeb && FirebaseConfig.webApiKey.isEmpty) {
    debugPrint(
      'WARNING: FIREBASE_WEB_API_KEY was not supplied at build time, so Firebase '
      'sign-in will fail. Render the config and pass it to the build: '
      'WEB_API_KEY=<key> scripts/generate_build_config.sh web, then build/run '
      'with --dart-define-from-file=config/firebase_config.json.',
    );
  }
  await Firebase.initializeApp(options: FirebaseConfig.forCurrentPlatform);
  runApp(MyApp());
}

const String title = "Options";

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Demo Option Pricing App',
        theme: ThemeData(
            primarySwatch: Colors.teal,
            // `ThemeData.accentColor` was removed. The secondary slot of the
            // colour scheme replaces it, and it is the value the density and
            // put-price charts read through `colorScheme.secondary`, so this
            // is the one place that decides that orange.
            colorScheme: ColorScheme.fromSwatch(
              primarySwatch: Colors.teal,
            ).copyWith(secondary: Colors.orange),
            buttonTheme: const ButtonThemeData(
              buttonColor: Colors.orange,
            ),
            textTheme: const TextTheme(
              // `bodyText2` is `bodyLarge` under the Material 3 text roles.
              bodyLarge: TextStyle(
                fontSize: 15.0,
              ),
            )),
        home: BlocProvider<ApiBloc>(
            create: (context) => ApiBloc(
                firebaseAuth: FirebaseAuth.instance,
                apiRepository: ApiRepository())
              ..add(ApiEvents.RequestApiKey),
            child: StartupPage()));
  }
}

class StartupPage extends StatelessWidget {
  const StartupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ApiBloc, ApiState>(
      builder: (BuildContext context, ApiState data) => switch (data) {
        ApiError(:final apiError) => Center(child: Text(apiError.toString())),
        ApiIsFetching() => const Center(child: CircularProgressIndicator()),
        // No token yet, so there is nothing to sign in with. A reason is shown
        // when the state carries one — e.g. a sign-in attempt that failed.
        ApiNoData(:final message) => Introduction(errorMessage: message),
        ApiToken(:final token) => BlocProvider<SelectModelBloc>(
            create: (context) => SelectModelBloc(),
            child: AppScaffold(title: title, apiKey: token),
          ),
      },
    );
  }
}
