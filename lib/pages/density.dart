import 'package:realoptions/blocs/density_bloc.dart';
import 'package:realoptions/models/progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:realoptions/models/response.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:realoptions/utils/chart_utils.dart' as utils;
import 'package:realoptions/components/CustomPadding.dart' as padding;
import 'package:realoptions/blocs/bloc_provider.dart';

class ShowDensity extends StatelessWidget {
  const ShowDensity({
    Key key,
  });
  @override
  Widget build(BuildContext context) {
    final DensityBloc bloc = BlocProvider.of<DensityBloc>(context);
    return StreamBuilder<StreamProgress>(
        stream: bloc.outDensityProgress,
        initialData: StreamProgress.Busy,
        builder: (buildContext, snapshot) {
          switch (snapshot.data) {
            case StreamProgress.Busy:
              return Center(child: CircularProgressIndicator());
            case StreamProgress.NoData:
              return Center(child: Text("Please submit parameters!"));
            case StreamProgress.DataRetrieved:
              return _Density();
            default:
              return Center(child: CircularProgressIndicator());
          }
        });
  }
}

class _Density extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final charts.Color densityColor = utils.convertColor(themeData.accentColor);
    final DensityBloc bloc = BlocProvider.of<DensityBloc>(context);
    return StreamBuilder<DensityAndVaR>(
        stream: bloc.outDensityController,
        builder: (buildContext, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          if (snapshot.data == null) {
            return Center(child: CircularProgressIndicator());
          }
          var density = snapshot.data.density;
          var valueAtRisk = snapshot.data.riskMetrics.valueAtRisk;
          var expectedShortfall = snapshot.data.riskMetrics.expectedShortfall;
          var densitySeries = [
            charts.Series(
              id: 'Density',
              domainFn: (ModelResult optionData, _) => optionData.atPoint,
              measureFn: (ModelResult optionData, _) => optionData.value,
              colorFn: (ModelResult optionData, _) => densityColor,
              data: density,
            ), //..setAttribute(charts.rendererIdKey, 'customArea'),
            charts.Series(
              id: 'VaR',
              domainFn: (ModelResult optionData, _) => optionData.atPoint,
              measureFn: (ModelResult optionData, _) => optionData.value,
              colorFn: (ModelResult optionData, _) => densityColor,
              data:
                  density.where((data) => data.atPoint < valueAtRisk).toList(),
            )..setAttribute(charts.rendererIdKey, 'shadedforExpectedShortfall'),
          ];
          var domain = utils.getDomain(density);
          var range = utils.getDensityRange(density);
          var densityChart = charts.LineChart(densitySeries,
              animate: true,
              domainAxis: charts.NumericAxisSpec(tickProviderSpec: domain),
              primaryMeasureAxis:
                  charts.NumericAxisSpec(tickProviderSpec: range),
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
        });
  }
}
