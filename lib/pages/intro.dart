import 'package:realoptions/components/CustomPadding.dart';
import 'package:flutter/material.dart';
import 'package:realoptions/blocs/bloc_provider.dart';
import 'package:realoptions/blocs/api_bloc.dart';
import 'package:realoptions/components/SocialMediaButton.dart';
import 'package:realoptions/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Introduction extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ApiBloc bloc = BlocProvider.of<ApiBloc>(context);
    return StreamBuilder<FirebaseAuth>(
        stream: bloc.outAuth,
        builder: (buildContext, snapshot) {
          if (snapshot.hasError) {
            //should never get here
            return Center(child: Text(snapshot.error.toString()));
          }
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
                      style: TextStyle(
                          fontSize: 32.0, fontWeight: FontWeight.w600),
                    ))),
                SizedBox(height: 32.0),
                PaddingForm(
                  child: signInSheet(context, snapshot.data, bloc),
                )
              ]));
        });
  }
}

Widget signInSheet(BuildContext context, FirebaseAuth auth, ApiBloc bloc) {
  return Column(key: Key("SignIn"), children: [
    SocialSignInButton(
      key: Key("google"),
      assetName: 'assets/google-logo_small.png',
      text: "Sign in with Google",
      onPressed: () => handleGoogleSignIn(auth).then(bloc.setKeyFromUser),
      color: Colors.white,
    ),
    SocialSignInButton(
      key: Key("facebook"),
      assetName: 'assets/fb-logo.png',
      text: "Sign in with Facebook",
      textColor: Colors.white,
      onPressed: () => handleFacebookSignIn(auth).then(bloc.setKeyFromUser),
      color: Color(0xFF334D92),
    ),
  ]);
}
