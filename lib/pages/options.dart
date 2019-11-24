import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:demo_api_app_flutter/services/data_models.dart' as data_model;
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:demo_api_app_flutter/components/CustomPadding.dart' as padding;
charts.Color convertColor(Color color){
  return charts.Color(
    r: color.red, g: color.green, b: color.blue, a: color.alpha
  );
}
var blue=convertColor(Colors.blue);
var orange=convertColor(Colors.orange);


class ShowOptionPrices extends StatelessWidget {
  const ShowOptionPrices({
    Key key,
    this.callOption,
    this.putOption,
  });
  final data_model.ModelResults callOption;
  final data_model.ModelResults putOption;
  @override
  Widget build(BuildContext context){
    var optionSeries=[
      charts.Series(
        id: 'Call Prices',
        domainFn: (data_model.ModelResult optionData, _) => optionData.atPoint,
        measureFn: (data_model.ModelResult optionData, _) => optionData.value,
        colorFn: (data_model.ModelResult optionData, _) => blue,
        data: this.callOption.results,
      ),
      charts.Series(
        id: 'Put Prices',
        domainFn: (data_model.ModelResult optionData, _) => optionData.atPoint,
        measureFn: (data_model.ModelResult optionData, _) => optionData.value,
        colorFn: (data_model.ModelResult optionData, _) => orange,
        data: this.putOption.results,
      )
    ];
    var optionChart = charts.LineChart(
      optionSeries,
      animate: true,
    );
    var ivSeries=[
      charts.Series(
        id:'implied volatility',
        data: this.callOption.results,
        domainFn: (data_model.ModelResult optionData, _) => optionData.atPoint,
        measureFn: (data_model.ModelResult optionData, _) => optionData.iv,
        colorFn: (data_model.ModelResult optionData, _) => orange,
      )
    ];
    var ivChart=charts.LineChart(ivSeries, animate:true);
    return Column(
      children:[
        padding.PaddingForm(
          child: SizedBox(
            height: 300.0,
            child: optionChart,
          ),
        ),
        padding.PaddingForm(
          child: SizedBox(
            height: 300.0,
            child: ivChart,
          ),
        ),
      ]
    );

  }
}