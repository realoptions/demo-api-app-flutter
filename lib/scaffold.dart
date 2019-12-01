import 'package:demo_api_app_flutter/blocs/constraints_bloc.dart';
import 'package:demo_api_app_flutter/blocs/api_bloc.dart';
import 'package:demo_api_app_flutter/blocs/select_model_bloc.dart';
import 'package:demo_api_app_flutter/services/finside_service.dart';
import 'package:flutter/material.dart';
import 'package:demo_api_app_flutter/models/pages.dart';
import 'package:demo_api_app_flutter/components/app_bar.dart';
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
                final ApiKey apiKey = snapshot.data;
                final FinsideApi finside =
                    FinsideApi(apiKey: apiKey.key, model: model.value);
                if (apiKey == null) {
                  return Center(child: CircularProgressIndicator());
                }
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
                              child: _Scaffold(title: this.title),
                            ))));
              });
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
