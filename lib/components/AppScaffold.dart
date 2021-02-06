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
  AppScaffold({Key key, @required this.title, @required this.apiKey});
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
  const WaitForConstraints(
      {Key key,
      @required this.title,
      //@required this.selectPageBloc,
      @required this.finside})
      : super(key: key);
  final String title;
  final FinsideApi finside;
  //final SelectPageBloc selectPageBloc;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConstraintsBloc, ConstraintsState>(
      builder: (context, data) {
        if (data is ConstraintsIsFetching) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (data is ConstraintsError) {
          return Scaffold(
              body: Center(child: Text(data.constraintsError.toString())));
        } else if (data is ConstraintsData) {
          return MultiBlocProvider(providers: [
            BlocProvider<OptionsBloc>(create: (_) {
              return OptionsBloc(
                  finside: finside,
                  selectPageBloc: context.read<SelectPageBloc>());
            }),
            BlocProvider<DensityBloc>(create: (_) {
              return DensityBloc(
                  finside: finside,
                  selectPageBloc: context.read<SelectPageBloc>());
            }),
            BlocProvider<FormBloc>(create: (context) {
              return FormBloc(constraints: data.constraints);
            }),
          ], child: _Scaffold(title: title));
        } else {
          //should never get here
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
      },
    );
  }
}

class _Scaffold extends StatelessWidget {
  _Scaffold({@required this.title});
  final String title;
  final PageStorageBucket _bucket = PageStorageBucket();
  List<PageEntry> _getPages(List<bool> showBadge) {
    return [
      PageEntry(
        widget: InputForm(),
        icon: Icon(Icons.input),
        text: "Entry",
      ),
      PageEntry(
          widget: ShowDensity(),
          icon: badge.ShowBadge(
              icon: Icon(Icons.show_chart), showBadge: showBadge[DENSITY_PAGE]),
          text: "Density"),
      PageEntry(
          widget: ShowOptionPrices(),
          icon: badge.ShowBadge(
              icon: Icon(Icons.scatter_plot),
              showBadge: showBadge[OPTIONS_PAGE]),
          text: "Prices"),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectPageBloc, PageState>(
      builder: (context, data) {
        final selectedIndex = data.index;
        final showBadges = data.showBadges;
        final pages = _getPages(showBadges);
        return Scaffold(
            appBar: OptionsAppBar(
              title: this.title,
              choices: MODEL_CHOICES,
            ),
            body: PageStorage(
                child: pages[selectedIndex].widget, bucket: _bucket),
            bottomNavigationBar: BottomNavigationBar(
              items: pages.map((PageEntry entry) {
                return BottomNavigationBarItem(
                    icon: entry.icon, label: entry.text);
              }).toList(),
              currentIndex: selectedIndex,
              onTap: (index) => context.read<SelectPageBloc>().setPage(index),
            ));
      },
    );
  }
}
