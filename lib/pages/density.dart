import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:realoptions/blocs/density/density_bloc.dart';
import 'package:realoptions/blocs/density/density_state.dart';
import 'package:realoptions/components/CustomPadding.dart' as padding;
import 'package:realoptions/models/response.dart';
import 'package:realoptions/utils/chart_utils.dart' as utils;

class ShowDensity extends StatelessWidget {
  const ShowDensity({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DensityBloc, DensityState>(builder: (context, data) {
      if (data is DensityNoData) {
        return const Center(child: Text('Please submit parameters!'));
      } else if (data is IsDensityFetching) {
        return const Center(child: CircularProgressIndicator());
      } else if (data is DensityData) {
        return _Density(density: data.density);
      } else if (data is DensityError) {
        return Center(child: Text(data.densityError));
      } else {
        return const Center(child: CircularProgressIndicator());
      }
    });
  }
}

class _Density extends StatelessWidget {
  const _Density({required this.density});

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

    // Value at Risk is quoted as a positive loss, so the threshold on the domain
    // axis sits at -valueAtRisk; everything left of it is the tail that the
    // expected shortfall averages over.
    final double varThreshold = -valueAtRisk;

    final utils.AxisRange domain = utils.getDomain(densityPlot);
    final utils.AxisRange range = utils.getDensityRange(densityPlot);

    final LineChartBarData densityLine = LineChartBarData(
      spots: utils.toSpots(densityPlot, (ModelResult r) => r.value.toDouble()),
      isCurved: true,
      color: densityColor,
      barWidth: 2,
      dotData: const FlDotData(show: false),
    );

    // The tail beyond VaR, filled down to the axis. This replaces the second
    // series that charts_flutter drew through a `customSeriesRenderers`
    // `LineRendererConfig(includeArea: true)`; fl_chart expresses the same thing
    // as `belowBarData` on the bar itself.
    final LineChartBarData shortfallArea = LineChartBarData(
      spots: utils.toSpots(
        densityPlot.where(
          (ModelResult r) => r.atPoint.toDouble() < varThreshold,
        ),
        (ModelResult r) => r.value.toDouble(),
      ),
      isCurved: true,
      color: shortfallColor,
      barWidth: 2,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: shortfallColor.withValues(alpha: 0.22),
      ),
    );

    final LineChart chart = LineChart(
      LineChartData(
        minX: domain.min,
        maxX: domain.max,
        minY: range.min,
        maxY: range.max,
        lineBarsData: [densityLine, shortfallArea],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: range.sideTitles(reservedSize: 52),
          ),
          bottomTitles: AxisTitles(
            sideTitles: domain.sideTitles(reservedSize: 34),
          ),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: theme.dividerColor),
            bottom: BorderSide(color: theme.dividerColor),
          ),
        ),
        // The VaR marker. Previously a charts_flutter RangeAnnotation with a
        // multi-line end label; fl_chart puts the same text on a VerticalLine.
        extraLinesData: ExtraLinesData(
          verticalLines: [
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
        ),
      ),
    );

    return OrientationBuilder(
      builder: (BuildContext context, Orientation orientation) {
        return GridView.count(
          crossAxisCount: orientation == Orientation.portrait ? 1 : 2,
          children: [
            padding.PaddingForm(child: chart),
          ],
        );
      },
    );
  }
}
