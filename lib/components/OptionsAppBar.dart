import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:realoptions/blocs/constraints/constraints_bloc.dart';
import 'package:realoptions/blocs/select_model/select_model_bloc.dart';
import 'package:realoptions/models/models.dart';
import 'package:url_launcher/url_launcher.dart';

/// App bar that also reports the model currently selected.
///
/// Declared `implements PreferredSizeWidget` rather than `with`: the Dart 3
/// class hierarchy no longer lets a plain interface be mixed in, and there was
/// nothing to inherit here anyway - only `preferredSize` was being supplied.
class OptionsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const OptionsAppBar({required this.title, required this.choices});

  final String title;
  final List<Model> choices;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectModelBloc, Model>(
        builder: (context, selectedModel) {
      return AppBar(
        key: const Key('AppBarComponent'),
        title: Text('$title: ${selectedModel.label}'),
        actions: <Widget>[
          IconButton(
              icon: const Icon(Icons.help),
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                          title: const Text('Help'),
                          content: SingleChildScrollView(
                            child: ListBody(
                              children: <Widget>[
                                const Text(
                                    '''This app calculates option prices for three models: Heston, CGMY with a diffusion and a stochastic clock, and Merton jump-diffusion with stochastic clock.  It uses Fang and Oosterlee's algorithm for efficient pricing across many strikes.'''),
                                ElevatedButton(
                                  onPressed: () => _launchDocs(context),
                                  child: const Text('References'),
                                ),
                              ],
                            ),
                          ));
                    });
              }),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              showModalBottomSheet<void>(
                  context: context,
                  builder: (BuildContext modalContext) {
                    return ListView(
                        shrinkWrap: true,
                        children: choices
                            .map((Model choice) => RadioListTile<Model>(
                                title: Text(choice.label),
                                value: choice,
                                groupValue: selectedModel,
                                // RadioListTile hands back a nullable: the radio
                                // can be toggled off. There is no "no model"
                                // state here, so a null selection is ignored
                                // rather than pushed into the blocs.
                                onChanged: (Model? picked) {
                                  if (picked == null) return;
                                  context
                                      .read<SelectModelBloc>()
                                      .setModel(picked);
                                  context
                                      .read<ConstraintsBloc>()
                                      .getConstraints(picked);
                                  Navigator.pop(modalContext);
                                }))
                            .toList());
                  });
            },
          ),
        ],
      );
    });
  }
}

/// The technical reference could not be opened.
///
/// A real [Exception] rather than a bare `String`. Throwing a String is a
/// holdover from the JS side of the house: it satisfies `throw` in Dart, but it
/// is not an `Exception`, so callers cannot `on`-catch it, `toString()` on it
/// is just the raw text with no type to key on, and it defeats any handler that
/// filters on `is Exception`.
class DocsLaunchException implements Exception {
  const DocsLaunchException(this.url, this.reason);

  final Uri url;
  final String reason;

  String get message => 'Could not open the reference document: $reason';

  @override
  String toString() => 'DocsLaunchException($url): $reason';
}

/// Opens the technical reference PDF in an external handler.
///
/// Takes a [BuildContext] so a failure can be *shown* to the user. Previously
/// the failure was thrown and nothing caught it: an uncaught async error out of
/// an `onPressed` callback lands in the ambient zone, which means a red
/// exception screen under a debug build and complete silence in release - the
/// tap appears to do nothing. Reporting through the ScaffoldMessenger makes the
/// failure visible in both.
Future<void> _launchDocs(BuildContext context) async {
  // `launch`/`canLaunch` are the deprecated string-taking legacy API; the
  // current one works on a parsed Uri.
  final Uri url = Uri.parse(
      'https://raw.githubusercontent.com/realoptions/option_price_faas/master/techdoc/OptionCalculation.pdf');
  try {
    if (!await canLaunchUrl(url)) {
      throw DocsLaunchException(url, 'no app is registered to open it');
    }
    await launchUrl(url);
  } on DocsLaunchException catch (error) {
    _reportLaunchFailure(context, error);
  } catch (error) {
    // launchUrl itself can throw (platform channel failure, bad mode, etc).
    // Fold anything else into the same reported failure rather than letting it
    // reach the zone.
    _reportLaunchFailure(context, DocsLaunchException(url, error.toString()));
  }
}

void _reportLaunchFailure(BuildContext context, DocsLaunchException error) {
  // The dialog that held the button may already be gone by the time the
  // platform round-trip fails; touching a dead context is worse than the
  // error we are trying to report.
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(error.message)));
}
