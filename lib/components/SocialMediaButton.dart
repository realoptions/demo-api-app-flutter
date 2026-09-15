///Copied from https://github.com/bizz84/firebase_auth_demo_flutter/blob/master/lib/app/sign_in/social_sign_in_button.dart
library;

import 'package:realoptions/components/CustomButtons.dart';
import 'package:flutter/material.dart';

class SocialSignInButton extends CustomRaisedButton {
  SocialSignInButton({
    super.key,
    required String assetName,
    required String text,
    Color super.color = Colors.white,
    super.textColor,
    super.onPressed,
  }) : super(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Image.asset(assetName),
              Text(
                text,
                style: TextStyle(color: textColor, fontSize: 15.0),
              ),
              // Balances the leading logo so the label sits centred.
              Opacity(
                opacity: 0.0,
                child: Image.asset(assetName),
              ),
            ],
          ),
        );
}

class SignInButton extends CustomRaisedButton {
  SignInButton({
    super.key,
    required String text,
    required Color super.color,
    required VoidCallback super.onPressed,
    Color super.textColor = Colors.black87,
    super.height,
  }) : super(
          child: Text(text, style: TextStyle(color: textColor, fontSize: 15.0)),
        );
}
