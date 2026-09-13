import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;

/// Build-time switches for the hosted (GitHub Pages) demo.
///
/// The demo is served to people evaluating the project who have no business
/// signing in to someone else's Firebase project with a social account: the
/// OAuth client IDs belong to a project they do not control, and the page is
/// not in their authorised origins. Without another way in, the demo degrades
/// to a login screen that most reviewers cannot get past.
///
/// These are compile-time switches rather than runtime settings so a production
/// build cannot accidentally grow a guest door: the flag is baked in by
/// `--dart-define` at build time and read here.
class DemoConfig {
  const DemoConfig._();

  /// Whether the sign-in screen offers "Continue as guest" (anonymous Firebase
  /// auth) next to the social buttons.
  ///
  /// Defaults to on for the web build — the web build *is* the demo — and off
  /// everywhere else, so the mobile app keeps social sign-in only. Override
  /// explicitly with `--dart-define=DEMO_GUEST_LOGIN=true` / `=false`, which
  /// is also how a non-web build can be exercised against the guest path.
  ///
  /// Note this only *offers* the door; the Firebase project must have the
  /// Anonymous sign-in provider enabled. If it is not, anonymous sign-in fails
  /// and [ApiBloc] puts the user back on the sign-in screen rather than
  /// stranding them on a spinner.
  static bool get guestLoginEnabled => resolveGuestLogin(
        isWeb: kIsWeb,
        override: const String.fromEnvironment('DEMO_GUEST_LOGIN'),
      );

  /// The rule behind [guestLoginEnabled], split out so it can be exercised
  /// without rebuilding the binary under different `--dart-define` values.
  @visibleForTesting
  static bool resolveGuestLogin({
    required bool isWeb,
    required String override,
  }) {
    if (override.isNotEmpty) {
      return override == 'true';
    }
    return isWeb;
  }
}
