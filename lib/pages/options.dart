import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:demo_api_app_flutter/models/response.dart' as response_model;
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:demo_api_app_flutter/utils/chart_utils.dart' as utils;
import 'package:demo_api_app_flutter/components/CustomPadding.dart' as padding;

var teal=utils.convertColor(Colors.teal);
var orange=utils.convertColor(Colors.orange);

class ShowOptionPrices extends StatelessWidget {
  const ShowOptionPrices({
    Key key,
    @required this.callOption,
    @required this.putOption,
  });
  final response_model.ModelResults callOption;
  final response_model.ModelResults putOption;
  @override
  Widget build(BuildContext context){
    var optionSeries=[
      charts.Series(
        id: 'Call Prices',
        domainFn: (response_model.ModelResult optionData, _) => optionData.atPoint,
        measureFn: (response_model.ModelResult optionData, _) => optionData.value,
        colorFn: (response_model.ModelResult optionData, _) => teal,
        data: this.callOption.results,
      ),
      charts.Series(
        id: 'Put Prices',
        domainFn: (response_model.ModelResult optionData, _) => optionData.atPoint,
        measureFn: (response_model.ModelResult optionData, _) => optionData.value,
        colorFn: (response_model.ModelResult optionData, _) => orange,
        data: this.putOption.results,
      )
    ];
    var domain=utils.getDomain(callOption);
    var optionChart = charts.LineChart(
      optionSeries,
      animate: true,
      domainAxis: charts.NumericAxisSpec(
        tickProviderSpec: domain
      ),
      behaviors: [charts.SeriesLegend()],
    );
    var ivSeries=[
      charts.Series(
        id:'Implied Volatility',
        data: this.callOption.results,
        domainFn: (response_model.ModelResult optionData, _) => optionData.atPoint,
        measureFn: (response_model.ModelResult optionData, _) => optionData.iv,
        colorFn: (response_model.ModelResult optionData, _) => orange,
      )
    ];
    var range=utils.getIVRange(callOption);
    var ivChart=charts.LineChart(
      ivSeries, 
      animate:true, 
      domainAxis: charts.NumericAxisSpec(
        tickProviderSpec: domain
      ),
      primaryMeasureAxis: charts.NumericAxisSpec(tickProviderSpec: range),
      behaviors: [charts.SeriesLegend()],
    );
    return SingleChildScrollView(
      child: Column(
        children:[
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
        ]
      ),
      key: PageStorageKey("Options")
    );
  }
}