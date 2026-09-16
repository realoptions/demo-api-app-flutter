import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration for the web build.
///
/// Only the non-secret identifiers live in this tracked file. The web API key is
/// read with [String.fromEnvironment], i.e. supplied at build time from
/// `config/firebase_config.json`:
///
/// ```
/// flutter build web --release --dart-define-from-file=config/firebase_config.json
/// ```
///
/// That JSON is rendered from `config/firebase_config.json.template` by
/// `scripts/generate_build_config.sh`, the only place the live key is ever seen.
/// It is gitignored, and because it is read from a file rather than a
/// `--dart-define` argument it never reaches a child process argv either — the
/// same property the Android `google-services.json` rendering has.
///
/// This replaces the previous setup, where the key, a pinned Firebase JS SDK
/// (7.9.3, several majors behind the one `firebase_core_web` was built against)
/// and a Google OAuth client ID were all pasted into `web/index.html`. The JS
/// SDK is now owned by `firebase_core_web`. The app carries no Google OAuth
/// client ID at all: web sign-in goes through Firebase's own popup, and Google
/// is configured on the Firebase project — see `ApiRepository._signInWithPopup`
/// in `lib/repositories/api_repository.dart`.
class FirebaseConfig {
  const FirebaseConfig._();

  /// The Firebase web API key, or `''` when it was not supplied at build time.
  static const String webApiKey =
      String.fromEnvironment('FIREBASE_WEB_API_KEY');

  /// Web app options; [apiKey] comes from the build environment, see above.
  static const FirebaseOptions webOptions = FirebaseOptions(
    apiKey: webApiKey,
    appId: '1:117231459701:web:01dad1d92d5df68cf7c73c',
    messagingSenderId: '117231459701',
    projectId: 'finside',
    storageBucket: 'finside.appspot.com',
    authDomain: 'finside.firebaseapp.com',
    databaseURL: 'https://finside.firebaseio.com',
    measurementId: 'G-1DYJD80BEB',
  );

  /// Options for the platform the app is running on.
  ///
  /// `null` off the web, where the SDK reads its own config file
  /// (`android/app/google-services.json`, itself rendered from a template).
  static FirebaseOptions? get forCurrentPlatform => kIsWeb ? webOptions : null;
}
