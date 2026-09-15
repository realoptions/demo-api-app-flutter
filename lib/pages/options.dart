import 'package:flutter/material.dart';

import 'package:realoptions/blocs/options/options_bloc.dart';
import 'package:realoptions/blocs/options/options_state.dart';
import 'package:realoptions/components/ChartPage.dart';
import 'package:realoptions/models/response.dart';
import 'package:realoptions/utils/chart_utils.dart' as utils;

class ShowOptionPrices extends StatelessWidget {
  const ShowOptionPrices({super.key});

  @override
  Widget build(BuildContext context) {
    return ChartPage<OptionsBloc, OptionsState>(
      resolve: (BuildContext context, OptionsState state) => switch (state) {
        OptionsNoData() => const ChartEmpty(),
        IsOptionsFetching() => const ChartBusy(),
        OptionsError(:final optionsError) => ChartFailed(optionsError),
        OptionsData(:final options) =>
          ChartReady(_optionCharts(context, options)),
      },
    );
  }
}

/// The options page's charts: call and put prices against strike, then the
/// implied-volatility curve over the same strikes.
///
/// Each entry becomes one cell of the responsive grid [ChartPage] lays out.
List<Widget> _optionCharts(BuildContext context, OptionPrices options) {
  final ThemeData theme = Theme.of(context);
  final Color callColor = theme.colorScheme.primary;
  final Color putColor = theme.colorScheme.secondary;

  final List<ModelResult> callPrices = options.calls;
  final List<ModelResult> putPrices = options.puts;

  // Both charts share the strike axis, so the domain is computed once.
  final utils.AxisRange domain = utils.getDomain(callPrices);

  // Option prices against strike. The vertical range is left to the chart here,
  // matching the previous chart, which set no measure-axis tick provider and
  // let calls and puts share one scale.
  final Widget optionChart = utils.LegendChart(
    entries: [
      utils.ChartLegendEntry(label: 'Call prices', color: callColor),
      utils.ChartLegendEntry(label: 'Put prices', color: putColor),
    ],
    chart: utils.lineChart(
      theme: theme,
      x: domain,
      series: [
        utils.chartSeries(callPrices, color: callColor),
        utils.chartSeries(putPrices, color: putColor),
      ],
    ),
  );

  // Implied volatility across the same strikes. This is the call curve only -
  // the API returns `iv` on calls, which is what the old chart plotted too.
  final utils.AxisRange ivRange = utils.getIVRange(callPrices);
  final Widget ivChart = utils.LegendChart(
    entries: [
      utils.ChartLegendEntry(label: 'Implied volatility', color: putColor),
    ],
    chart: utils.lineChart(
      theme: theme,
      x: domain,
      y: ivRange,
      series: [
        utils.chartSeries(
          callPrices,
          color: putColor,
          y: (ModelResult r) => r.iv?.toDouble() ?? 0.0,
        ),
      ],
    ),
  );

  return [optionChart, ivChart];
}
