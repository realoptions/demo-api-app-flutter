import 'package:demo_api_app_flutter/components/StreamsBuilder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:demo_api_app_flutter/models/response.dart' as response_model;
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:demo_api_app_flutter/utils/chart_utils.dart' as utils;
import 'package:demo_api_app_flutter/components/CustomPadding.dart' as padding;
import 'package:demo_api_app_flutter/blocs/bloc_provider.dart';
import 'package:demo_api_app_flutter/blocs/options_bloc.dart';

var teal = utils.convertColor(Colors.teal);
var orange = utils.convertColor(Colors.orange);

class ShowOptionPrices extends StatelessWidget {
  const ShowOptionPrices({
    Key key,
  });
  @override
  Widget build(BuildContext context) {
    final OptionsBloc bloc = BlocProvider.of<OptionsBloc>(context);
    return StreamsBuilder(
        streams: [bloc.outCallResults, bloc.outPutResults],
        initialData: [null, null],
        builder: (buildContext, snapshots) {
          var callPrices = snapshots[0].data;
          var putPrices = snapshots[1].data;
          var optionSeries = [
            charts.Series(
              id: 'Call Prices',
              domainFn: (response_model.ModelResult optionData, _) =>
                  optionData.atPoint,
              measureFn: (response_model.ModelResult optionData, _) =>
                  optionData.value,
              colorFn: (response_model.ModelResult optionData, _) => teal,
              data: callPrices,
            ),
            charts.Series(
              id: 'Put Prices',
              domainFn: (response_model.ModelResult optionData, _) =>
                  optionData.atPoint,
              measureFn: (response_model.ModelResult optionData, _) =>
                  optionData.value,
              colorFn: (response_model.ModelResult optionData, _) => orange,
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
              domainFn: (response_model.ModelResult optionData, _) =>
                  optionData.atPoint,
              measureFn: (response_model.ModelResult optionData, _) =>
                  optionData.iv,
              colorFn: (response_model.ModelResult optionData, _) => orange,
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
