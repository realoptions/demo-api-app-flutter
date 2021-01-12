import 'package:realoptions/components/CustomPadding.dart';
import 'package:flutter/material.dart';
import 'package:realoptions/blocs/api/api_bloc.dart';
import 'package:realoptions/components/SocialMediaButton.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Introduction extends StatelessWidget {
  Introduction();
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
            SizedBox(height: 8),
            SocialSignInButton(
              key: Key("facebook"),
              assetName: 'assets/fb-logo.png',
              text: "Sign in with Facebook",
              textColor: Colors.white,
              onPressed: () => context.read<ApiBloc>().handleFacebookSignIn(),
              color: Color(0xFF334D92),
            ),
          ]))
        ]));
  }
}
/*
Widget signInSheet(BuildContext context) {
  return Column(key: Key("SignIn"), children: [
    SocialSignInButton(
      key: Key("google"),
      assetName: 'assets/go-logo.png',
      text: "Sign in with Google",
      onPressed: () => context.read<ApiBloc>().handleGoogleSignIn(),
      color: Colors.white,
    ),
    SizedBox(height: 8),
    SocialSignInButton(
      key: Key("facebook"),
      assetName: 'assets/fb-logo.png',
      text: "Sign in with Facebook",
      textColor: Colors.white,
      onPressed: () => context.read<ApiBloc>().handleFacebookSignIn(),
      color: Color(0xFF334D92),
    ),
  ]);
}
*/
