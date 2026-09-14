///Copied from https://github.com/bizz84/firebase_auth_demo_flutter/blob/master/lib/app/sign_in/social_sign_in_button.dart
import 'package:realoptions/components/CustomButtons.dart';
import 'package:flutter/material.dart';

class SocialSignInButton extends CustomRaisedButton {
  SocialSignInButton({
    super.key,
    required String assetName,
    required String text,
    Color color = Colors.white,
    Color? textColor,
    VoidCallback? onPressed,
  }) : super(
          color: color,
          textColor: textColor,
          onPressed: onPressed,
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
    required Color color,
    required VoidCallback onPressed,
    Color textColor = Colors.black87,
    double height = 50.0,
  }) : super(
          color: color,
          textColor: textColor,
          height: height,
          onPressed: onPressed,
          child: Text(text, style: TextStyle(color: textColor, fontSize: 15.0)),
        );
}
