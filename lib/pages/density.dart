import 'package:demo_api_app_flutter/blocs/density_bloc.dart';
import 'package:demo_api_app_flutter/models/progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:demo_api_app_flutter/models/response.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:demo_api_app_flutter/utils/chart_utils.dart' as utils;
import 'package:demo_api_app_flutter/components/CustomPadding.dart' as padding;
import 'package:demo_api_app_flutter/blocs/bloc_provider.dart';

var orange = utils.convertColor(Colors.orange);

class ShowDensity extends StatelessWidget {
  const ShowDensity({
    Key key,
    //@required this.density,
  });
  //final response_model.ModelResults density;
  @override
  Widget build(BuildContext context) {
    final DensityBloc bloc = BlocProvider.of<DensityBloc>(context);
    return StreamBuilder<StreamProgress>(
        stream: bloc.outDensityProgress,
        initialData: StreamProgress.Busy,
        builder: (buildContext, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
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
  _Density();
  @override
  Widget build(BuildContext context) {
    final DensityBloc bloc = BlocProvider.of<DensityBloc>(context);
    return StreamBuilder<ModelResults>(
        stream: bloc.outDensityResults,
        builder: (buildContext, snapshot) {
          if (snapshot.data == null) {
            return Center(child: CircularProgressIndicator());
          }
          var density = snapshot.data;
          var densitySeries = [
            charts.Series(
              id: 'Density',
              domainFn: (ModelResult optionData, _) => optionData.atPoint,
              measureFn: (ModelResult optionData, _) => optionData.value,
              colorFn: (ModelResult optionData, _) => orange,
              data: density.results,
            ),
          ];
          var domain = utils.getDomain(density);
          var range = utils.getDensityRange(density);
          var densityChart = charts.LineChart(
            densitySeries,
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
                    child: densityChart,
                  ),
                ),
              ]),
              key: PageStorageKey("density"));
        });
  }
}
