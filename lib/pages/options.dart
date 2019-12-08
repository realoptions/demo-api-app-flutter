import 'package:realoptions/models/progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:realoptions/models/response.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:realoptions/utils/chart_utils.dart' as utils;
import 'package:realoptions/components/CustomPadding.dart' as padding;
import 'package:realoptions/blocs/bloc_provider.dart';
import 'package:realoptions/blocs/options_bloc.dart';

class ShowOptionPrices extends StatelessWidget {
  const ShowOptionPrices({
    Key key,
  });
  @override
  Widget build(BuildContext context) {
    final OptionsBloc bloc = BlocProvider.of<OptionsBloc>(context);
    return StreamBuilder<StreamProgress>(
        stream: bloc.outOptionsProgress,
        initialData: StreamProgress.Busy,
        builder: (buildContext, snapshot) {
          switch (snapshot.data) {
            case StreamProgress.Busy:
              return Center(child: CircularProgressIndicator());
            case StreamProgress.NoData:
              return Center(child: Text("Please submit parameters!"));
            case StreamProgress.DataRetrieved:
              return _OptionPrices();
            default:
              return Center(child: CircularProgressIndicator());
          }
        });
  }
}

class _OptionPrices extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final OptionsBloc bloc = BlocProvider.of<OptionsBloc>(context);
    final ThemeData themeData = Theme.of(context);
    final charts.Color callColor = utils.convertColor(themeData.primaryColor);
    final charts.Color putColor = utils.convertColor(themeData.accentColor);
    return StreamBuilder<Map<String, List<ModelResult>>>(
        stream: bloc.outOptionResults,
        builder: (buildContext, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          if (snapshot.data == null) {
            return Center(child: CircularProgressIndicator());
          }
          var callPrices = snapshot.data["call"];
          var putPrices = snapshot.data["put"];
          var optionSeries = [
            charts.Series(
              id: 'Call Prices',
              domainFn: (ModelResult optionData, _) => optionData.atPoint,
              measureFn: (ModelResult optionData, _) => optionData.value,
              colorFn: (ModelResult optionData, _) => callColor,
              data: callPrices,
            ),
            charts.Series(
              id: 'Put Prices',
              domainFn: (ModelResult optionData, _) => optionData.atPoint,
              measureFn: (ModelResult optionData, _) => optionData.value,
              colorFn: (ModelResult optionData, _) => putColor,
              data: putPrices,
            )
          ];
          var domain = utils.getDomain(callPrices);
          var optionChart = charts.LineChart(
            optionSeries,
            animate: true,
            domainAxis: charts.NumericAxisSpec(tickProviderSpec: domain),
            behaviors: [charts.SeriesLegend()],
          );
          var ivSeries = [
            charts.Series(
              id: 'Implied Volatility',
              data: callPrices,
              domainFn: (ModelResult optionData, _) => optionData.atPoint,
              measureFn: (ModelResult optionData, _) => optionData.iv,
              colorFn: (ModelResult optionData, _) => putColor,
            )
          ];
          var range = utils.getIVRange(callPrices);
          var ivChart = charts.LineChart(
            ivSeries,
            animate: true,
            domainAxis: charts.NumericAxisSpec(tickProviderSpec: domain),
            primaryMeasureAxis: charts.NumericAxisSpec(tickProviderSpec: range),
            behaviors: [charts.SeriesLegend()],
          );
          return SingleChildScrollView(
              child: Column(children: [
                padding.PaddingForm(
                  child: AspectRatio(
                    aspectRatio: 1.2,
                    child: optionChart,
                  ),
                ),
                padding.PaddingForm(
                  child: AspectRatio(
                    aspectRatio: 1.2,
                    child: ivChart,
                  ),
                ),
              ]),
              key: PageStorageKey("Options"));
        });
  }
}
