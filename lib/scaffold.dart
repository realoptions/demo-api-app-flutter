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
import 'package:demo_api_app_flutter/components/StreamsBuilder.dart';

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
    final ApiBloc apiBloc = BlocProvider.of<ApiBloc>(context);
    return StreamsBuilder(
        streams: [
          selectBloc.outSelectedModel,
          apiBloc.outApiKey,
        ],
        initialData: [
          modelChoices[0],
          ""
        ],
        builder: (buildContext, snapshots) {
          return BlocProvider<SelectPageBloc>(
              bloc: SelectPageBloc(),
              child: _Scaffold(
                  model: snapshots[0].data,
                  apiKey: snapshots[1].data,
                  title: title));
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
        widget: BlocProvider<ConstraintsBloc>(
          bloc: ConstraintsBloc(modelValue, apiKey),
          child: InputForm(),
        ),
        icon: Icon(Icons.input),
        text: "Entry",
      ),
      PageEntry(
          widget: BlocProvider<DensityBloc>(
              bloc: DensityBloc(), child: ShowDensity()),
          icon: badge.ShowBadge(
              icon: Icon(Icons.show_chart), showBadge: showBadge[1]),
          text: "Density"),
      PageEntry(
          widget: BlocProvider<OptionsBloc>(
              bloc: OptionsBloc(), child: ShowOptionPrices()),
          icon: badge.ShowBadge(
              icon: Icon(Icons.scatter_plot), showBadge: showBadge[2]),
          text: "Prices"),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final SelectPageBloc pageBloc = BlocProvider.of<SelectPageBloc>(context);
    return StreamsBuilder(
        streams: [
          pageBloc.outPageController,
          pageBloc.outPageClickedController,
        ],
        initialData: [
          0,
          [false, false, false]
        ],
        builder: (buildContext, snapshots) {
          int selectedIndex = snapshots[0].data;
          List<bool> showBadges = snapshots[1].data;
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
                onTap: pageBloc.setPageIndex.add,
              ));
        });
  }
}
