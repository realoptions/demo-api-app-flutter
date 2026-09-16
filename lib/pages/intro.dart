import 'package:realoptions/components/CustomPadding.dart';
import 'package:flutter/material.dart';
import 'package:realoptions/blocs/api/api_bloc.dart';
import 'package:realoptions/components/SocialMediaButton.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The sign-in screen.
///
/// Google is the only provider offered.
///
/// * Facebook was removed. The web build has no Facebook app id to log in with:
///   `FacebookAuth.instance.login` was never preceded by an
///   `initialize(appId: …)`, `web/index.html.template` has no `fb-root` or SDK
///   script, and no app id appears in the deployed bundle. The button was
///   therefore incapable of completing a login for anyone.
/// * "Continue as guest" (anonymous Firebase auth) was removed because the
///   hosting project does not permit anonymous sign-in, so the door led to a
///   failed sign-in rather than into the demo.
///
/// [errorMessage] is rendered under the button when the previous attempt failed.
/// Without it a failed sign-in returned here with no trace of having been
/// attempted — see `ApiNoData.message` in `lib/blocs/api/api_state.dart`.
class Introduction extends StatelessWidget {
  const Introduction({super.key, this.errorMessage});

  /// Why the previous sign-in attempt did not complete, if it did not.
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: Key("Intro"),
        body: Column(children: <Widget>[
          SizedBox(height: 32.0),
          SizedBox(
              height: 50.0,
              child: PaddingForm(
                  child: Text(
                "Sign in",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32.0, fontWeight: FontWeight.w600),
              ))),
          SizedBox(height: 32.0),
          PaddingForm(
              child: Column(key: Key("SignIn"), children: [
            SocialSignInButton(
              key: Key("google"),
              assetName: 'assets/go-logo.png',
              text: "Sign in with Google",
              onPressed: () => context.read<ApiBloc>().handleGoogleSignIn(),
              color: Colors.white,
            ),
            if (errorMessage != null) ...[
              SizedBox(height: 12.0),
              Text(
                errorMessage!,
                key: Key("signInError"),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.0, color: Colors.red),
              ),
            ],
          ]))
        ]));
  }
}
