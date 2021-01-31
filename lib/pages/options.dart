import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realoptions/blocs/options/options_bloc.dart';
import 'package:realoptions/blocs/options/options_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:realoptions/models/response.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:realoptions/utils/chart_utils.dart' as utils;
import 'package:realoptions/components/CustomPadding.dart' as padding;

class ShowOptionPrices extends StatelessWidget {
  const ShowOptionPrices({
    Key key,
  });
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OptionsBloc, OptionsState>(builder: (context, data) {
      if (data is NoData) {
        return Center(child: Text("Please submit parameters!"));
      } else if (data is IsOptionsFetching) {
        return Center(child: CircularProgressIndicator());
      } else if (data is OptionsData) {
        return _OptionPrices(options: data.options);
      } else if (data is OptionsError) {
        return Center(child: Text(data.optionsError));
      } else {
        return Center(child: CircularProgressIndicator());
      }
    });
  }
}

class _OptionPrices extends StatelessWidget {
  final Map<String, List<ModelResult>> options;
  _OptionPrices({@required this.options});
  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final charts.Color callColor = utils.convertColor(themeData.primaryColor);
    final charts.Color putColor = utils.convertColor(themeData.accentColor);

    final callPrices = options["call"];
    final putPrices = options["put"];
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
    var children = [
      padding.PaddingForm(
        child: optionChart,
      ),
      padding.PaddingForm(
        child: ivChart,
      ),
    ];
    return OrientationBuilder(builder: (context, orientation) {
      return GridView.count(
          crossAxisCount: orientation == Orientation.portrait ? 1 : 2,
          children: children);
    });
  }
}
