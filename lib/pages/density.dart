import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:realoptions/blocs/density/density_bloc.dart';
import 'package:realoptions/blocs/density/density_state.dart';
import 'package:realoptions/components/ChartPage.dart';
import 'package:realoptions/models/response.dart';
import 'package:realoptions/utils/chart_utils.dart' as utils;

class ShowDensity extends StatelessWidget {
  const ShowDensity({super.key});

  @override
  Widget build(BuildContext context) {
    return ChartPage<DensityBloc, DensityState>(
      resolve: (BuildContext context, DensityState state) => switch (state) {
        DensityNoData() => const ChartEmpty(),
        IsDensityFetching() => const ChartBusy(),
        DensityError(:final densityError) => ChartFailed(densityError),
        DensityData(:final density) =>
          ChartReady(<Widget>[_DensityChart(density: density)]),
      },
    );
  }
}

/// The density plot: the curve itself, with the tail beyond Value at Risk
/// shaded down to the axis.
class _DensityChart extends StatelessWidget {
  const _DensityChart({required this.density});

  final DensityAndVaR density;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color densityColor = theme.colorScheme.secondary;
    final Color shortfallColor = theme.colorScheme.tertiary;

    final List<ModelResult> densityPlot = density.density;
    final double valueAtRisk = density.riskMetrics.valueAtRisk.toDouble();
    final double expectedShortfall =
        density.riskMetrics.expectedShortfall.toDouble();

    // Value at Risk is quoted as a positive loss, so the threshold on the
    // domain axis sits at -valueAtRisk; everything left of it is the tail that
    // the expected shortfall averages over.
    final double varThreshold = -valueAtRisk;

    final utils.AxisRange domain = utils.getDomain(densityPlot);
    final utils.AxisRange range = utils.getDensityRange(densityPlot);

    return utils.lineChart(
      theme: theme,
      x: domain,
      y: range,
      series: [
        utils.chartSeries(densityPlot, color: densityColor),
        utils.chartSeries(
          densityPlot.where(
            (ModelResult r) => r.atPoint.toDouble() < varThreshold,
          ),
          color: shortfallColor,
          fill: shortfallColor,
        ),
      ],
      verticalLines: [
        // The VaR marker. Previously a charts_flutter RangeAnnotation with a
        // multi-line end label; fl_chart puts the same text on a VerticalLine.
        VerticalLine(
          x: varThreshold,
          color: theme.colorScheme.error,
          strokeWidth: 1.5,
          dashArray: const [6, 4],
          label: VerticalLineLabel(
            show: true,
            alignment: Alignment.topLeft,
            direction: LabelDirection.horizontal,
            labelResolver: (_) =>
                'Value at Risk: ${valueAtRisk.toStringAsFixed(3)}\n'
                'Expected Shortfall: ${expectedShortfall.toStringAsFixed(3)}',
          ),
        ),
      ],
    );
  }
}
