import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:realoptions/models/response.dart';

const int NUM_TICKS = 5;
const double PADDING_PERCENTAGE = 0.15;

/// A numeric axis range carrying a fixed count of evenly spaced ticks.
///
/// charts_flutter let a chart pin an axis to an explicit tick list through
/// `StaticNumericTickProviderSpec`. fl_chart has no equivalent: it derives tick
/// labels from an `interval` laid across the chart's own min/max. Those two have
/// to agree or the labels drift off the data they describe, so the range and the
/// interval are computed together here and handed out as one unit - the chart
/// takes [min]/[max] for its `minX`/`maxY`, the axis takes [sideTitles].
class AxisRange {
  const AxisRange(this.min, this.max,
      {this.ticks = NUM_TICKS, this.decimals = 1});

  final double min;
  final double max;
  final int ticks;

  /// Decimal places used when rendering a tick label.
  final int decimals;

  double get interval => ticks > 1 ? (max - min) / (ticks - 1) : 0.0;

  List<double> get values =>
      [for (var i = 0; i < ticks; i++) min + interval * i];

  /// Titles for one side of an axis spanning this range.
  SideTitles sideTitles({double reservedSize = 44}) => SideTitles(
        showTitles: true,
        // fl_chart asserts that interval is non-zero; a degenerate (single-value)
        // range asks for no interval and just renders its one label.
        interval: interval > 0 ? interval : null,
        reservedSize: reservedSize,
        getTitlesWidget: (double value, TitleMeta meta) => SideTitleWidget(
          meta: meta,
          child: Text(
            value.toStringAsFixed(decimals),
            style: const TextStyle(fontSize: 11),
          ),
        ),
      );
}

/// Evenly spaced tick values from [firstPoint] to [lastPoint], inclusive.
List<double> getAxis(num firstPoint, num lastPoint, {int ticks = NUM_TICKS}) =>
    AxisRange(firstPoint.toDouble(), lastPoint.toDouble(), ticks: ticks).values;

/// The horizontal axis: the range of `at_point` (strike / underlying level).
///
/// Returns a unit-width range when there is nothing to plot rather than throwing
/// the way `List.first` did on an empty response.
AxisRange getDomain(List<ModelResult> modelResults) {
  if (modelResults.isEmpty) return const AxisRange(0, 1, decimals: 1);
  return AxisRange(
    modelResults.first.atPoint.toDouble(),
    modelResults.last.atPoint.toDouble(),
    decimals: 1,
  );
}

/// Implied-volatility axis, padded by [PADDING_PERCENTAGE] at both ends so the
/// curve does not sit flush against the plot border.
///
/// `iv` is nullable - the API only returns it when implied volatility was asked
/// for - so absent values are dropped instead of poisoning the range.
AxisRange getIVRange(List<ModelResult> modelResults) {
  final List<double> ivs = modelResults
      .map((ModelResult r) => r.iv)
      .nonNulls
      .map((num v) => v.toDouble())
      .toList();
  if (ivs.isEmpty) return const AxisRange(0, 1, decimals: 2);
  final double minIV = ivs.reduce(math.min) * (1.0 - PADDING_PERCENTAGE);
  final double maxIV = ivs.reduce(math.max) * (1.0 + PADDING_PERCENTAGE);
  return AxisRange(minIV, maxIV, decimals: 2);
}

/// Density axis: fixed at zero on the bottom (a density is never negative, and
/// pinning the floor keeps the curve comparable between submissions) up to the
/// padded peak.
AxisRange getDensityRange(List<ModelResult> modelResults) {
  if (modelResults.isEmpty) return const AxisRange(0, 1, decimals: 3);
  final double maxVal =
      modelResults.map((ModelResult r) => r.value.toDouble()).reduce(math.max);
  return AxisRange(0.0, maxVal * (1.0 + PADDING_PERCENTAGE), decimals: 3);
}

/// Maps [results] onto the chart's x axis with [y] supplying the vertical value.
List<FlSpot> toSpots(
  Iterable<ModelResult> results,
  double Function(ModelResult result) y,
) =>
    [
      for (final ModelResult r in results) FlSpot(r.atPoint.toDouble(), y(r)),
    ];

/// One swatch-and-label pair in a [ChartLegend].
class ChartLegendEntry {
  const ChartLegendEntry({required this.label, required this.color});

  final String label;
  final Color color;
}

/// A legend for a chart's series.
///
/// fl_chart 1.x removed the `SeriesLegend` behaviour that charts_flutter
/// provided, so the key is assembled here from the very same [Color] objects the
/// series were drawn with - a legend that drifts from the line it names is worse
/// than no legend.
class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key, required this.entries});

  final List<ChartLegendEntry> entries;

  @override
  Widget build(BuildContext context) {
    final TextStyle style =
        Theme.of(context).textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 4,
      children: [
        for (final ChartLegendEntry entry in entries)
          Semantics(
            label: '${entry.label} series',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: entry.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(entry.label, style: style),
              ],
            ),
          ),
      ],
    );
  }
}

/// Wraps a chart with its legend underneath, so every chart in the app presents
/// the same shape and the legend never overlaps the plot.
class LegendChart extends StatelessWidget {
  const LegendChart({
    super.key,
    required this.chart,
    required this.entries,
  });

  final Widget chart;
  final List<ChartLegendEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: chart),
        const SizedBox(height: 8),
        ChartLegend(entries: entries),
      ],
    );
  }
}
