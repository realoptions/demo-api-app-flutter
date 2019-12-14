import 'package:realoptions/blocs/constraints_bloc.dart';
import 'package:realoptions/blocs/api_bloc.dart';
import 'package:realoptions/blocs/select_model_bloc.dart';
import 'package:realoptions/services/finside_service.dart';
import 'package:flutter/material.dart';
import 'package:realoptions/models/pages.dart';
import 'package:realoptions/components/OptionsAppBar.dart';
import 'package:realoptions/pages/form.dart';
import 'package:realoptions/pages/options.dart';
import 'package:realoptions/pages/density.dart';
import 'package:realoptions/components/ShowBadge.dart' as badge;
import 'package:realoptions/models/models.dart';
import 'package:realoptions/blocs/bloc_provider.dart';
import 'package:realoptions/blocs/select_page_bloc.dart';
import 'package:realoptions/blocs/options_bloc.dart';
import 'package:realoptions/blocs/density_bloc.dart';
import 'package:realoptions/models/progress.dart';
import 'package:realoptions/models/forms.dart';
import 'package:realoptions/blocs/form_bloc.dart';

class AppScaffold extends StatelessWidget {
  AppScaffold({
    Key key,
    @required this.title,
  });
  final String title;

  @override
  Widget build(BuildContext context) {
    final SelectModelBloc selectBloc =
        BlocProvider.of<SelectModelBloc>(context);

    return StreamBuilder<Model>(
        initialData: modelChoices[0],
        stream: selectBloc.outSelectedModel,
        builder: (buildContext, snapshot) {
          final ApiBloc apiBloc = BlocProvider.of<ApiBloc>(context);
          final Model model = snapshot.data;
          return StreamBuilder<String>(
              stream: apiBloc.outApiKey,
              builder: (buildContext, snapshot) {
                final String apiKey = snapshot.data;
                if (apiKey == null) {
                  return Scaffold(
                      body: Center(child: CircularProgressIndicator()));
                }
                final FinsideApi finside =
                    FinsideApi(apiKey: apiKey, model: model.value);
                return BlocProvider<ConstraintsBloc>(
                    bloc: ConstraintsBloc(finside: finside),
                    child: BlocProvider<DensityBloc>(
                        bloc: DensityBloc(
                            finside:
                                finside), //needed so we can get the functions "getDensity" and "getOptionPrices" in the submit function
                        child: BlocProvider<OptionsBloc>(
                            bloc: OptionsBloc(finside: finside),
                            child: BlocProvider<SelectPageBloc>(
                                bloc: SelectPageBloc(),
                                child: WaitForConstraints(
                                  child: _Scaffold(title: title),
                                )))));
              });
        });
  }
}

class WaitForConstraints extends StatelessWidget {
  const WaitForConstraints({
    Key key,
    @required this.child,
  }) : super(key: key);
  final Widget child;
  @override
  Widget build(BuildContext context) {
    ConstraintsBloc bloc = BlocProvider.of<ConstraintsBloc>(context);
    return StreamBuilder<StreamProgress>(
        stream: bloc.outConstraintsProgress,
        builder: (buildContext, snapshot) {
          switch (snapshot.data) {
            case StreamProgress.Busy:
              return Scaffold(body: Center(child: CircularProgressIndicator()));
            case StreamProgress.DataRetrieved:
              return StreamBuilder<List<InputConstraint>>(
                  stream: bloc.outConstraintsController,
                  builder: (buildContext, snapshot) {
                    if (snapshot.hasError) {
                      return Scaffold(
                          body: Center(child: Text(snapshot.error.toString())));
                    }
                    if (snapshot.data == null) {
                      return Scaffold(
                          body: Center(child: CircularProgressIndicator()));
                    }
                    return BlocProvider<FormBloc>(
                        bloc: FormBloc(constraints: snapshot.data),
                        child: child);
                  });
            default: //should never get here
              return Scaffold(body: Center(child: CircularProgressIndicator()));
          }
        });
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
    final SelectPageBloc pageBloc = BlocProvider.of<SelectPageBloc>(context);
    return StreamBuilder<PageState>(
        stream: pageBloc.outPageController,
        initialData: PageState(index: 0, showBadges: [false, false, false]),
        builder: (buildContext, snapshots) {
          int selectedIndex = snapshots.data.index;
          List<bool> showBadges = snapshots.data.showBadges;
          var pages = _getPages(showBadges);
          return Scaffold(
              appBar: OptionsAppBar(
                title: this.title,
                choices: modelChoices,
              ),
              body: PageStorage(
                  child: pages[selectedIndex].widget, bucket: _bucket),
              bottomNavigationBar: BottomNavigationBar(
                items: pages.map((PageEntry entry) {
                  return BottomNavigationBarItem(
                      icon: entry.icon, title: Text(entry.text));
                }).toList(),
                currentIndex: selectedIndex,
                onTap: pageBloc.setPage,
              ));
        });
  }
}
