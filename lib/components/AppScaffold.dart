import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realoptions/blocs/api/api_bloc.dart';
import 'package:realoptions/blocs/constraints/constraints_bloc.dart';
import 'package:realoptions/blocs/constraints/constraints_events.dart';
import 'package:realoptions/blocs/constraints/constraints_state.dart';
import 'package:realoptions/blocs/options/options_bloc.dart';
import 'package:realoptions/blocs/density/density_bloc.dart';
import 'package:realoptions/blocs/select_model/select_model_bloc.dart';
import 'package:realoptions/services/finside_service.dart';
import 'package:flutter/material.dart';
import 'package:realoptions/models/pages.dart';
import 'package:realoptions/components/OptionsAppBar.dart';
import 'package:realoptions/pages/form.dart';
import 'package:realoptions/pages/options.dart';
import 'package:realoptions/pages/density.dart';
import 'package:realoptions/components/ShowBadge.dart' as badge;
import 'package:realoptions/models/models.dart';
import 'package:realoptions/blocs/select_page/select_page_bloc.dart';
import 'package:realoptions/blocs/form/form_bloc.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key, required this.title, required this.apiKey});
  final String title;
  final String apiKey;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectModelBloc, Model>(builder: (context, data) {
      final FinsideApi finside = FinsideApi(apiKey: apiKey);
      return MultiBlocProvider(providers: [
        BlocProvider<ConstraintsBloc>(
            create: (context) => ConstraintsBloc(
                finside: finside, apiBloc: context.read<ApiBloc>())
              ..add(RequestConstraints(model: data))),
        BlocProvider<SelectPageBloc>(create: (context) => SelectPageBloc())
      ], child: WaitForConstraints(finside: finside, title: title));
    });
  }
}

class WaitForConstraints extends StatelessWidget {
  const WaitForConstraints({
    super.key,
    required this.title,
    required this.finside,
  });
  final String title;
  final FinsideApi finside;
  //final SelectPageBloc selectPageBloc;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConstraintsBloc, ConstraintsState>(
      builder: (BuildContext context, ConstraintsState data) => switch (data) {
        ConstraintsIsFetching() =>
          Scaffold(body: Center(child: CircularProgressIndicator())),
        ConstraintsError(:final constraintsError) =>
          Scaffold(body: Center(child: Text(constraintsError))),
        // The form and both chart blocs need the constraints, so they are
        // provided here rather than re-fetched downstream.
        ConstraintsData(:final constraints) => MultiBlocProvider(
            providers: [
              BlocProvider<OptionsBloc>(
                create: (_) => OptionsBloc(
                    finside: finside,
                    selectPageBloc: context.read<SelectPageBloc>()),
              ),
              BlocProvider<DensityBloc>(
                create: (_) => DensityBloc(
                    finside: finside,
                    selectPageBloc: context.read<SelectPageBloc>()),
              ),
              BlocProvider<FormBloc>(
                create: (_) => FormBloc(constraints: constraints),
              ),
            ],
            child: _Scaffold(title: title),
          ),
      },
    );
  }
}

class _Scaffold extends StatefulWidget {
  const _Scaffold({required this.title});
  final String title;

  @override
  State<_Scaffold> createState() => _ScaffoldState();
}

class _ScaffoldState extends State<_Scaffold> {
  /// The three pages of the shell, allocated once rather than per build.
  ///
  /// This used to be a `_getPages(showBadges)` call run on every build, which
  /// threw away the page bodies and rebuilt every `Icon` just to flip two
  /// badge booleans. Held as `const` instead: the instances are canonicalised,
  /// so a rebuild hands the tree the identical widget and Flutter can skip the
  /// work below it. The badge flag - the only thing that actually varies - is
  /// applied in [_navIcon], on top of the shared icon.
  static const List<PageEntry> _pages = <PageEntry>[
    PageEntry(
      widget: InputForm(),
      icon: Icon(Icons.input),
      text: "Entry",
    ),
    PageEntry(
      widget: ShowDensity(),
      icon: Icon(Icons.show_chart),
      text: "Density",
    ),
    PageEntry(
      widget: ShowOptionPrices(),
      icon: Icon(Icons.scatter_plot),
      text: "Prices",
    ),
  ];

  /// Tabs that carry a "new results" dot. Entry is not one of them - nothing
  /// ever marks it read or unread - so its icon stays unwrapped, exactly as it
  /// was when the badge was baked into the page entry.
  static const Set<int> _badgePages = <int>{DENSITY_PAGE, OPTIONS_PAGE};

  late final PageStorageBucket _bucket;

  @override
  void initState() {
    super.initState();
    // The bucket is mutable storage state: scroll offsets and any other
    // PageStorage reads and writes live in it. It used to be a field on the
    // StatelessWidget, where a new widget instance at any time would drop it
    // (or, if the instance was reused, quietly share it) - a StatelessWidget
    // has no place to keep it.
    _bucket = PageStorageBucket();
  }

  Widget _navIcon(int index, List<bool> showBadges) {
    final Widget icon = _pages[index].icon;
    if (!_badgePages.contains(index)) {
      return icon;
    }
    return badge.ShowBadge(icon: icon, showBadge: showBadges[index]);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectPageBloc, PageState>(
      builder: (context, data) {
        final selectedIndex = data.index;
        final showBadges = data.showBadges;
        return Scaffold(
            appBar: OptionsAppBar(
              title: widget.title,
              choices: MODEL_CHOICES,
            ),
            body: PageStorage(
                bucket: _bucket, child: _pages[selectedIndex].widget),
            bottomNavigationBar: BottomNavigationBar(
              items: [
                for (int index = 0; index < _pages.length; index++)
                  BottomNavigationBarItem(
                      icon: _navIcon(index, showBadges),
                      label: _pages[index].text),
              ],
              currentIndex: selectedIndex,
              onTap: (index) => context.read<SelectPageBloc>().setPage(index),
            ));
      },
    );
  }
}
