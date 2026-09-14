import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:realoptions/blocs/options/options_bloc.dart';
import 'package:realoptions/blocs/options/options_state.dart';
import 'package:realoptions/components/CustomPadding.dart' as padding;
import 'package:realoptions/models/response.dart';
import 'package:realoptions/utils/chart_utils.dart' as utils;

class ShowOptionPrices extends StatelessWidget {
  const ShowOptionPrices({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OptionsBloc, OptionsState>(builder: (context, data) {
      if (data is NoData) {
        return const Center(child: Text('Please submit parameters!'));
      } else if (data is IsOptionsFetching) {
        return const Center(child: CircularProgressIndicator());
      } else if (data is OptionsData) {
        return _OptionPrices(options: data.options);
      } else if (data is OptionsError) {
        return Center(child: Text(data.optionsError));
      } else {
        return const Center(child: CircularProgressIndicator());
      }
    });
  }
}

class _OptionPrices extends StatelessWidget {
  const _OptionPrices({required this.options});

  final OptionPrices options;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color callColor = theme.colorScheme.primary;
    final Color putColor = theme.colorScheme.secondary;

    final List<ModelResult> callPrices = options.calls;
    final List<ModelResult> putPrices = options.puts;

    final utils.AxisRange domain = utils.getDomain(callPrices);

    LineChartBarData bar({
      required List<ModelResult> results,
      required Color color,
      required double Function(ModelResult result) y,
    }) =>
        LineChartBarData(
          spots: utils.toSpots(results, y),
          isCurved: true,
          color: color,
          barWidth: 2,
          dotData: const FlDotData(show: false),
        );

    FlTitlesData titles({
      required utils.AxisRange x,
      utils.AxisRange? y,
    }) =>
        FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: x.sideTitles(reservedSize: 34)),
          leftTitles: y == null
              ? const AxisTitles()
              : AxisTitles(sideTitles: y.sideTitles(reservedSize: 52)),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
        );

    FlBorderData border(ThemeData theme) => FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: theme.dividerColor),
            bottom: BorderSide(color: theme.dividerColor),
          ),
        );

    // Option prices against strike. The vertical range is left to fl_chart here,
    // matching the previous chart, which set no measure-axis tick provider and
    // let calls and puts share one scale.
    final Widget optionChart = utils.LegendChart(
      entries: [
        utils.ChartLegendEntry(label: 'Call prices', color: callColor),
        utils.ChartLegendEntry(label: 'Put prices', color: putColor),
      ],
      chart: LineChart(
        LineChartData(
          minX: domain.min,
          maxX: domain.max,
          lineBarsData: [
            bar(
              results: callPrices,
              color: callColor,
              y: (ModelResult r) => r.value.toDouble(),
            ),
            bar(
              results: putPrices,
              color: putColor,
              y: (ModelResult r) => r.value.toDouble(),
            ),
          ],
          titlesData: titles(x: domain),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: border(theme),
        ),
      ),
    );

    // Implied volatility across the same strikes. This is the call curve only -
    // the API returns `iv` on calls, which is what the old chart plotted too.
    final utils.AxisRange ivRange = utils.getIVRange(callPrices);
    final Widget ivChart = utils.LegendChart(
      entries: [
        utils.ChartLegendEntry(
          label: 'Implied volatility',
          color: putColor,
        ),
      ],
      chart: LineChart(
        LineChartData(
          minX: domain.min,
          maxX: domain.max,
          minY: ivRange.min,
          maxY: ivRange.max,
          lineBarsData: [
            bar(
              results: callPrices,
              color: putColor,
              y: (ModelResult r) => r.iv?.toDouble() ?? 0.0,
            ),
          ],
          titlesData: titles(x: domain, y: ivRange),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: border(theme),
        ),
      ),
    );

    return OrientationBuilder(
      builder: (BuildContext context, Orientation orientation) {
        return GridView.count(
          crossAxisCount: orientation == Orientation.portrait ? 1 : 2,
          children: [
            padding.PaddingForm(child: optionChart),
            padding.PaddingForm(child: ivChart),
          ],
        );
      },
    );
  }
}
