import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:demo_api_app_flutter/services/data_models.dart' as data_model;
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:demo_api_app_flutter/utils/chart_utils.dart' as utils;
import 'package:demo_api_app_flutter/components/CustomPadding.dart' as padding;

var orange=utils.convertColor(Colors.orange);

class ShowDensity extends StatelessWidget {
  const ShowDensity({
    Key key,
    @required this.density,
  });
  final data_model.ModelResults density;
  @override
  Widget build(BuildContext context){
    var densitySeries=[
      charts.Series(
        id: 'Density',
        domainFn: (data_model.ModelResult optionData, _) => optionData.atPoint,
        measureFn: (data_model.ModelResult optionData, _) => optionData.value,
        colorFn: (data_model.ModelResult optionData, _) => orange,
        data: this.density.results,
      ),
    ];
    var densityChart = charts.LineChart(
      densitySeries,
      animate: true,
    );
    return SingleChildScrollView(
      child:Column(
        children:[
          padding.PaddingForm(
            child: SizedBox(
              height: 300.0,
              child: densityChart,
            ),
          ),
          
        ]
      ),
      key: PageStorageKey("density")
    );
  }
}