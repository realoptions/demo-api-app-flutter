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
                    builder: (BuildContext context) {
                      return const AlertDialog(
                          title: Text('Help'),
                          content: SingleChildScrollView(
                            child: ListBody(
                              children: <Widget>[
                                Text(
                                    '''This app calculates option prices for three models: Heston, CGMY with a diffusion and a stochastic clock, and Merton jump-diffusion with stochastic clock.  It uses Fang and Oosterlee's algorithm for efficient pricing across many strikes.'''),
                                ElevatedButton(
                                  onPressed: _launchDocs,
                                  child: Text('References'),
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

Future<void> _launchDocs() async {
  // `launch`/`canLaunch` are the deprecated string-taking legacy API; the
  // current one works on a parsed Uri.
  final Uri url = Uri.parse(
      'https://raw.githubusercontent.com/realoptions/option_price_faas/master/techdoc/OptionCalculation.pdf');
  if (!await canLaunchUrl(url)) {
    throw 'Could not launch $url';
  }
  await launchUrl(url);
}
