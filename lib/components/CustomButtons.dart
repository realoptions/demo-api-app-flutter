/// Copied from https://github.com/bizz84/firebase_auth_demo_flutter/blob/master/lib/services/firebase_auth_service.dart
import 'package:flutter/material.dart';

@immutable
class CustomRaisedButton extends StatelessWidget {
  const CustomRaisedButton({
    super.key,
    required this.child,
    this.color,
    this.textColor,
    this.height = 50.0,
    this.borderRadius = 4.0,
    this.loading = false,
    this.onPressed,
  });

  final Widget child;
  final Color? color;
  final Color? textColor;
  final double height;
  final double borderRadius;
  final bool loading;
  final VoidCallback? onPressed;

  Widget buildSpinner(BuildContext context) {
    // The old version recoloured `ThemeData.accentColor` and relied on
    // CircularProgressIndicator picking it up. accentColor no longer exists, and
    // the indicator takes a colour directly, so the Theme override is gone.
    return const SizedBox(
      width: 28,
      height: 28,
      child: CircularProgressIndicator(
        strokeWidth: 3.0,
        color: Colors.white70,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = ElevatedButton.styleFrom(
      textStyle: TextStyle(color: textColor),
      // `primary:` was the fill colour in the old styleFrom signature; it is
      // `backgroundColor:` now.
      backgroundColor: color,
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
