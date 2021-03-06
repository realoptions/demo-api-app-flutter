import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realoptions/blocs/density/density_bloc.dart';
import 'package:realoptions/blocs/density/density_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:realoptions/models/response.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:realoptions/utils/chart_utils.dart' as utils;
import 'package:realoptions/components/CustomPadding.dart' as padding;

class ShowDensity extends StatelessWidget {
  const ShowDensity({
    Key key,
  });
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DensityBloc, DensityState>(builder: (context, data) {
      if (data is NoData) {
        return Center(child: Text("Please submit parameters!"));
      } else if (data is IsDensityFetching) {
        return Center(child: CircularProgressIndicator());
      } else if (data is DensityData) {
        return _Density(density: data.density);
      } else if (data is DensityError) {
        return Center(child: Text(data.densityError));
      } else {
        return Center(child: CircularProgressIndicator());
      }
    });
  }
}

class _Density extends StatelessWidget {
  final DensityAndVaR density;
  _Density({@required this.density});
  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final charts.Color densityColor = utils.convertColor(themeData.accentColor);
    final densityPlot = density.density;
    final valueAtRisk = density.riskMetrics.valueAtRisk;
    final expectedShortfall = density.riskMetrics.expectedShortfall;
    var densitySeries = [
      charts.Series(
        id: 'Density',
        domainFn: (ModelResult optionData, _) => optionData.atPoint,
        measureFn: (ModelResult optionData, _) => optionData.value,
        colorFn: (ModelResult optionData, _) => densityColor,
        data: densityPlot,
      ),
      charts.Series(
        id: 'VaR',
        domainFn: (ModelResult optionData, _) => optionData.atPoint,
        measureFn: (ModelResult optionData, _) => optionData.value,
        colorFn: (ModelResult optionData, _) => densityColor,
        data: densityPlot.where((data) => data.atPoint < -valueAtRisk).toList(),
      )..setAttribute(charts.rendererIdKey, 'shadedforExpectedShortfall'),
    ];
    var domain = utils.getDomain(densityPlot);
    var range = utils.getDensityRange(densityPlot);
    var densityChart = charts.LineChart(densitySeries,
        animate: true,
        domainAxis: charts.NumericAxisSpec(tickProviderSpec: domain),
        primaryMeasureAxis: charts.NumericAxisSpec(tickProviderSpec: range),
        behaviors: [
          new charts.RangeAnnotation([
            new charts.LineAnnotationSegment(
              -valueAtRisk,
              charts.RangeAnnotationAxisType.domain,
              endLabel: "Value at Risk: " +
                  valueAtRisk.toStringAsFixed(3) +
                  ", \nExpected Shortfall: " +
                  expectedShortfall.toStringAsFixed(3),
              labelAnchor: charts.AnnotationLabelAnchor.start,
              labelDirection: charts.AnnotationLabelDirection.horizontal,
            )
          ])
        ],
        customSeriesRenderers: [
          new charts.LineRendererConfig(
              // ID used to link series to this renderer.
              customRendererId: 'shadedforExpectedShortfall',
              includeArea: true),
        ]);
    return OrientationBuilder(builder: (context, orientation) {
      return GridView.count(
          crossAxisCount: orientation == Orientation.portrait ? 1 : 2,
          children: [
            padding.PaddingForm(child: densityChart),
          ]);
    });
  }
}
