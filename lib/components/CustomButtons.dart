/// Copied from https://github.com/bizz84/firebase_auth_demo_flutter/blob/master/lib/services/firebase_auth_service.dart
import 'package:flutter/material.dart';

@immutable
class CustomRaisedButton extends StatelessWidget {
  const CustomRaisedButton({
    Key key,
    @required this.child,
    this.color,
    this.textColor,
    this.height = 50.0,
    this.borderRadius = 4.0,
    this.loading = false,
    this.onPressed,
  }) : super(key: key);
  final Widget child;
  final Color color;
  final Color textColor;
  final double height;
  final double borderRadius;
  final bool loading;
  final VoidCallback onPressed;

  Widget buildSpinner(BuildContext context) {
    final ThemeData data = Theme.of(context);
    return Theme(
      data: data.copyWith(accentColor: Colors.white70),
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 3.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = ElevatedButton.styleFrom(
      textStyle: TextStyle(color: textColor),
      primary: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(borderRadius),
        ),
      ),
    );
    return SizedBox(
      height: height,
      child: ElevatedButton(
        child: loading ? buildSpinner(context) : child,
        style: style,
        onPressed: onPressed,
      ),
    );
  }
}
