import 'package:realoptions/components/CustomPadding.dart';
import 'package:flutter/material.dart';
import 'package:realoptions/blocs/bloc_provider.dart';
import 'package:realoptions/blocs/api_bloc.dart';
import 'package:realoptions/components/SocialMediaButton.dart';
import 'package:realoptions/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';

//final FirebaseAuth _auth = FirebaseAuth.instance;

class Introduction extends StatelessWidget {
  final FirebaseAuth firebaseAuth;
  Introduction({@required this.firebaseAuth});
  @override
  Widget build(BuildContext context) {
    final ApiBloc bloc = BlocProvider.of<ApiBloc>(context);
    return Scaffold(
        key: Key("Intro"),
        body: Column(children: <Widget>[
          PaddingForm(child: Text("Sign In")),
          PaddingForm(
            child: signInSheet(context, firebaseAuth, bloc),
          )
        ]));
  }
}

Widget signInSheet(BuildContext context, FirebaseAuth auth, ApiBloc bloc) {
  return Column(key: Key("SignIn"), children: [
    SocialSignInButton(
      key: Key("google"),
      assetName: 'assets/google-logo-small.png',
      text: "Sign in with Google",
      onPressed: () => handleGoogleSignIn(auth).then(bloc.setKeyFromUser),
      color: Colors.white,
    ),
  ]);
}
