///Copied from https://github.com/bizz84/firebase_auth_demo_flutter/blob/master/lib/app/sign_in/social_sign_in_button.dart
import 'package:realoptions/components/CustomButtons.dart';
import 'package:flutter/material.dart';

class SocialSignInButton extends CustomRaisedButton {
  SocialSignInButton({
    Key key,
    String assetName,
    String text,
    Color color,
    Color textColor,
    VoidCallback onPressed,
  }) : super(
          key: key,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Image.asset(assetName),
              Text(
                text,
                style: TextStyle(color: textColor, fontSize: 15.0),
              ),
              Opacity(
                opacity: 0.0,
                child: Image.asset(assetName),
              ),
            ],
          ),
          color: color,
          onPressed: onPressed,
        );
}

class SignInButton extends CustomRaisedButton {
  SignInButton({
    Key key,
    @required String text,
    @required Color color,
    @required VoidCallback onPressed,
    Color textColor = Colors.black87,
    double height = 50.0,
  }) : super(
          key: key,
          child: Text(text, style: TextStyle(color: textColor, fontSize: 15.0)),
          color: color,
          textColor: textColor,
          height: height,
          onPressed: onPressed,
        );
}
