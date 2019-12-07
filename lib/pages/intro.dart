import 'package:demo_api_app_flutter/components/CustomPadding.dart';
import 'package:flutter/material.dart';
import 'package:demo_api_app_flutter/blocs/bloc_provider.dart';
import 'package:demo_api_app_flutter/blocs/api_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';

class Introduction extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ApiBloc bloc = BlocProvider.of<ApiBloc>(context);
    return Scaffold(
        key: Key("Intro"),
        body: Column(children: <Widget>[
          PaddingForm(
            child: introInformation(context),
          ),
          PaddingForm(
              child: TextFormField(
            decoration: InputDecoration(labelText: 'API Key'),
            onChanged: bloc.setApiKey,
            initialValue: "",
          )),
          PaddingForm(
              child: Align(
                  child: RaisedButton(
                      child: const Text('Save'), onPressed: bloc.saveApiKey),
                  alignment: Alignment.centerLeft))
        ]));
  }
}

class _LinkTextSpan extends TextSpan {
  // Beware!
  //
  // This class is only safe because the TapGestureRecognizer is not
  // given a deadline and therefore never allocates any resources.
  //
  // In any other situation -- setting a deadline, using any of the less trivial
  // recognizers, etc -- you would have to manage the gesture recognizer's
  // lifetime and call dispose() when the TextSpan was no longer being rendered.
  //
  // Since TextSpan itself is @immutable, this means that you would have to
  // manage the recognizer from outside the TextSpan, e.g. in the State of a
  // stateful widget that then hands the recognizer to the TextSpan.

  _LinkTextSpan({TextStyle style, String url, String text})
      : super(
            style: style,
            text: text ?? url,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                launch(url, forceSafariVC: false);
              });
}

Widget introInformation(BuildContext context) {
  final ThemeData themeData = Theme.of(context);
  final TextStyle aboutTextStyle = themeData.textTheme.body1;
  final TextStyle linkStyle =
      themeData.textTheme.body1.copyWith(color: themeData.accentColor);
  return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: RichText(
          text: TextSpan(children: <TextSpan>[
        TextSpan(
            style: aboutTextStyle,
            text:
                "Welcome to the demo application for Finside's Option Pricing API!  "
                "To start, please enter your API key.  This key can be obtained by "
                "logging into "),
        _LinkTextSpan(
            text: "finside.org", url: "https://finside.org", style: linkStyle),
        TextSpan(
            text: " and using the developer tab to retrieve your API key.",
            style: aboutTextStyle)
      ])));
}
