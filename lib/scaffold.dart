import 'package:demo_api_app_flutter/blocs/constraints_bloc.dart';
import 'package:demo_api_app_flutter/blocs/api_bloc.dart';
import 'package:demo_api_app_flutter/blocs/select_model_bloc.dart';
import 'package:flutter/material.dart';
import 'package:demo_api_app_flutter/models/pages.dart';
import 'package:demo_api_app_flutter/app_bar.dart';
import 'package:demo_api_app_flutter/pages/form.dart';
import 'package:demo_api_app_flutter/pages/options.dart';
import 'package:demo_api_app_flutter/pages/density.dart';
import 'package:demo_api_app_flutter/components/ShowBadge.dart' as badge;
import 'package:demo_api_app_flutter/models/models.dart';
import 'package:demo_api_app_flutter/models/api_key.dart';
import 'package:demo_api_app_flutter/blocs/bloc_provider.dart';
import 'package:demo_api_app_flutter/blocs/select_page_bloc.dart';
import 'package:demo_api_app_flutter/blocs/options_bloc.dart';
import 'package:demo_api_app_flutter/blocs/density_bloc.dart';

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
          return StreamBuilder<ApiKey>(
              stream: apiBloc.outApiKey,
              builder: (buildContext, snapshot) {
                print(
                    "should be called ohnly on load, when model changes, or when API changes");
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                  case ConnectionState.none:
                    return Center(child: CircularProgressIndicator());
                  case ConnectionState.active:
                  case ConnectionState.done:
                    final ApiKey apiKey = snapshot.data;
                    return BlocProvider<ConstraintsBloc>(
                        bloc: ConstraintsBloc(model.value, apiKey.key),
                        child: BlocProvider<DensityBloc>(
                            bloc:
                                DensityBloc(), //needed so we can get the functions "getDensity" and "getOptionPrices" in the submit function
                            child: BlocProvider<OptionsBloc>(
                                bloc: OptionsBloc(),
                                child: BlocProvider<SelectPageBloc>(
                                  bloc: SelectPageBloc(),
                                  child: _Scaffold(
                                      model: model,
                                      apiKey: apiKey,
                                      title: this.title),
                                ))));

                  default:
                    return Center(child: CircularProgressIndicator());
                }
              });
        });
  }
}

class _Scaffold extends StatelessWidget {
  _Scaffold(
      {@required this.model, @required this.apiKey, @required this.title});
  final Model model;
  final ApiKey apiKey;
  final String title;
  final PageStorageBucket _bucket = PageStorageBucket();
  List<PageEntry> _getPages(
      String modelValue, String apiKey, List<bool> showBadge) {
    return [
      PageEntry(
        widget: InputForm(model: modelValue, apiKey: apiKey),
        icon: Icon(Icons.input),
        text: "Entry",
      ),
      PageEntry(
          widget: ShowDensity(),
          icon: badge.ShowBadge(
              icon: Icon(Icons.show_chart), showBadge: showBadge[1]),
          text: "Density"),
      PageEntry(
          widget: ShowOptionPrices(),
          icon: badge.ShowBadge(
              icon: Icon(Icons.scatter_plot), showBadge: showBadge[2]),
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
          var pages = _getPages(this.model.value, apiKey.key, showBadges);
          return Scaffold(
              appBar: OptionPriceAppBar(
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
