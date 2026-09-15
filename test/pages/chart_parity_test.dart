import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:realoptions/blocs/density/density_bloc.dart';
import 'package:realoptions/blocs/options/options_bloc.dart';
import 'package:realoptions/blocs/select_page/select_page_bloc.dart';
import 'package:realoptions/models/response.dart';
import 'package:realoptions/pages/density.dart';
import 'package:realoptions/pages/options.dart';
import 'package:realoptions/utils/chart_utils.dart' as utils;

import '../mocks/finside_api_mock.dart';
import '../support/form_fixtures.dart';

/// Spread across negative and positive `at_point`s, with a VaR that cuts the
/// sample in two. The shaded tail is only observable if points fall on both
/// sides of the threshold; an all-positive fixture would pass with the shading
/// silently missing.
final DensityAndVaR densityFixture = DensityAndVaR(
  density: [
    ModelResult(value: 0.10, atPoint: -2.0),
    ModelResult(value: 0.40, atPoint: -1.0),
    ModelResult(value: 0.30, atPoint: 0.0),
    ModelResult(value: 0.05, atPoint: 1.0),
  ],
  riskMetrics: VaRResult(valueAtRisk: 0.5, expectedShortfall: 0.35),
);

final OptionPrices optionFixture = OptionPrices(
  calls: [
    ModelResult(value: 9.0, atPoint: 90, iv: 0.20),
    ModelResult(value: 5.0, atPoint: 100, iv: 0.25),
    ModelResult(value: 2.0, atPoint: 110, iv: 0.30),
  ],
  puts: [
    ModelResult(value: 1.0, atPoint: 90, iv: 0.22),
    ModelResult(value: 3.0, atPoint: 100, iv: 0.27),
    ModelResult(value: 7.0, atPoint: 110, iv: 0.33),
  ],
);

/// Value at Risk is quoted as a positive loss; on the domain axis the cut sits
/// at its negation.
double varThreshold(DensityAndVaR data) =>
    -data.riskMetrics.valueAtRisk.toDouble();

ThemeData themeFrom(Color seed) =>
    ThemeData(useMaterial3: false, colorSchemeSeed: seed);

/// Drives a real page to its data state and hands back what it drew.
///
/// Assertions read the [LineChartData] the page ended up rendering rather than
/// the helper that produced it, so the parity contract is checked at the seam a
/// library swap actually has to survive.
class Harness {
  Harness(this.tester, this.finside);

  final WidgetTester tester;
  final MockFinsideService finside;

  Future<LineChartData> density(ThemeData theme) async {
    final DensityBloc bloc =
        DensityBloc(finside: finside, selectPageBloc: SelectPageBloc());
    when(finside.fetchDensityAndVaR(any))
        .thenAnswer((_) => Future.value(densityFixture));
    await _settle(
      MaterialApp(
        theme: theme,
        home: BlocProvider<DensityBloc>(
          create: (_) => bloc,
          child: const ShowDensity(),
        ),
      ),
      () => bloc.getDensity(hestonRequest()),
    );
    return tester.widget<LineChart>(find.byType(LineChart)).data;
  }

  /// Both charts the options page draws, in tree order: prices first, implied
  /// volatility second.
  Future<List<LineChartData>> options(ThemeData theme) async {
    final OptionsBloc bloc =
        OptionsBloc(finside: finside, selectPageBloc: SelectPageBloc());
    when(finside.fetchOptionPrices(any))
        .thenAnswer((_) => Future.value(optionFixture));
    await _settle(
      MaterialApp(
        theme: theme,
        home: BlocProvider<OptionsBloc>(
          create: (_) => bloc,
          child: const ShowOptionPrices(),
        ),
      ),
      () => bloc.getOptions(hestonRequest()),
    );
    return tester
        .widgetList<LineChart>(find.byType(LineChart))
        .map((LineChart chart) => chart.data)
        .toList();
  }

  Future<void> _settle(Widget tree, void Function() submit) async {
    await tester.pumpWidget(tree);
    submit();
    await tester.pumpAndSettle();
    // Guard against asserting on a page that never left its loading state.
    expect(find.byType(CircularProgressIndicator), findsNothing);
  }
}

void main() {
  late MockFinsideService finside;

  setUp(() {
    finside = MockFinsideService();
  });

  group('call vs put price chart', () {
    testWidgets('draws both series over the shared strike axis',
        (tester) async {
      final List<LineChartData> charts =
          await Harness(tester, finside).options(themeFrom(Colors.teal));
      final LineChartData chart = charts.first;

      expect(chart.lineBarsData, hasLength(2));
      expect(chart.lineBarsData[0].spots.map((FlSpot s) => s.y).toList(),
          <double>[9.0, 5.0, 2.0]);
      expect(chart.lineBarsData[1].spots.map((FlSpot s) => s.y).toList(),
          <double>[1.0, 3.0, 7.0]);
      expect(chart.lineBarsData[1].spots.map((FlSpot s) => s.x).toList(),
          <double>[90.0, 100.0, 110.0]);
    });

    testWidgets('a legend names both series', (tester) async {
      await Harness(tester, finside).options(themeFrom(Colors.teal));

      expect(find.text('Call prices'), findsOneWidget);
      expect(find.text('Put prices'), findsOneWidget);
    });

    testWidgets('the legend cannot drift from the lines it names',
        (tester) async {
      final List<LineChartData> charts =
          await Harness(tester, finside).options(themeFrom(Colors.teal));
      final utils.ChartLegend legend = tester
          .widget<utils.ChartLegend>(find.byType(utils.ChartLegend).first);

      expect(
          legend.entries.map((utils.ChartLegendEntry e) => e.color).toList(),
          <Color>[
            charts[0].lineBarsData[0].color!,
            charts[0].lineBarsData[1].color!,
          ]);
    });
  });

  group('implied volatility chart', () {
    testWidgets('measures the iv field, not value', (tester) async {
      final List<LineChartData> charts =
          await Harness(tester, finside).options(themeFrom(Colors.teal));
      final List<double> plotted =
          charts[1].lineBarsData.single.spots.map((FlSpot s) => s.y).toList();

      expect(plotted, <double>[0.20, 0.25, 0.30]);
      // The same points plotted from `value` would be 9/5/2 - a different scale
      // entirely, so a selector regression cannot pass silently.
      expect(plotted, isNot(<double>[9.0, 5.0, 2.0]));
    });

    testWidgets('its axis is the padded iv range', (tester) async {
      final List<LineChartData> charts =
          await Harness(tester, finside).options(themeFrom(Colors.teal));
      final utils.AxisRange expected = utils.getIVRange(optionFixture.calls);

      expect(charts[1].minY, expected.min);
      expect(charts[1].maxY, expected.max);
    });
  });

  group('density chart and expected shortfall shading', () {
    testWidgets('the curve and the shaded tail are separate series',
        (tester) async {
      final LineChartData chart =
          await Harness(tester, finside).density(themeFrom(Colors.teal));

      expect(chart.lineBarsData, hasLength(2));
      expect(chart.lineBarsData[0].belowBarData.show, isFalse,
          reason: 'the density curve itself is a plain line');
      expect(chart.lineBarsData[1].belowBarData.show, isTrue,
          reason: 'the tail beyond VaR is filled down to the axis');
    });

    testWidgets('only the points below the VaR threshold are shaded',
        (tester) async {
      final LineChartData chart =
          await Harness(tester, finside).density(themeFrom(Colors.teal));
      final List<FlSpot> tail = chart.lineBarsData[1].spots;
      final Set<double> curve =
          chart.lineBarsData[0].spots.map((FlSpot s) => s.x).toSet();

      expect(tail.map((FlSpot s) => s.x).toList(), <double>[-2.0, -1.0]);
      for (final FlSpot spot in tail) {
        expect(spot.x, lessThan(varThreshold(densityFixture)));
      }
      // The tail is a slice of the curve, never data the curve does not show.
      expect(
        tail,
        everyElement(predicate<FlSpot>(
            (FlSpot s) => curve.contains(s.x), 'a point on the density curve')),
      );
    });

    testWidgets('a labelled line carries VaR and expected shortfall',
        (tester) async {
      final LineChartData chart =
          await Harness(tester, finside).density(themeFrom(Colors.teal));
      final List<VerticalLine> lines = chart.extraLinesData.verticalLines;

      expect(lines, hasLength(1));
      final VerticalLine line = lines.single;
      expect(line.x, varThreshold(densityFixture));
      expect(line.label.show, isTrue);
      // fl_chart paints this label on the canvas rather than as a Text widget,
      // so the resolver is the observable contract.
      final String label = line.label.labelResolver(line);
      expect(label, contains('Value at Risk: 0.500'));
      expect(label, contains('Expected Shortfall: 0.350'));
    });

    testWidgets('the vertical axis is clamped at zero and padded above',
        (tester) async {
      final LineChartData chart =
          await Harness(tester, finside).density(themeFrom(Colors.teal));
      final utils.AxisRange expected =
          utils.getDensityRange(densityFixture.density);

      expect(chart.minY, 0.0);
      expect(chart.maxY, closeTo(0.40 * (1 + utils.PADDING_PERCENTAGE), 1e-12));
      expect(chart.maxY, expected.max);
    });

    testWidgets('tick spacing comes from NUM_TICKS across the range',
        (tester) async {
      final LineChartData chart =
          await Harness(tester, finside).density(themeFrom(Colors.teal));
      final SideTitles left = chart.titlesData.leftTitles.sideTitles;

      expect(left.showTitles, isTrue);
      expect(left.interval, isNotNull);
      expect(left.interval!, closeTo(chart.maxY / (utils.NUM_TICKS - 1), 1e-12),
          reason:
              'the fixed tick count has to divide the padded range exactly');
    });
  });

  group('theme-aware colours (what replaced the convertColor shim)', () {
    testWidgets('series colours come from the ambient ColorScheme',
        (tester) async {
      final ThemeData theme = themeFrom(Colors.indigo);
      final Harness h = Harness(tester, finside);
      final List<LineChartData> charts = await h.options(theme);
      final LineChartData density = await h.density(theme);

      expect(charts[0].lineBarsData[0].color, theme.colorScheme.primary);
      expect(charts[0].lineBarsData[1].color, theme.colorScheme.secondary);
      expect(charts[1].lineBarsData.single.color, theme.colorScheme.secondary);
      expect(density.lineBarsData[0].color, theme.colorScheme.secondary);
      expect(density.lineBarsData[1].color, theme.colorScheme.tertiary);
    });

    testWidgets('a different theme recolours every series', (tester) async {
      final Harness h = Harness(tester, finside);
      final List<LineChartData> teal = await h.options(themeFrom(Colors.teal));
      final List<LineChartData> amber =
          await h.options(themeFrom(Colors.amber));
      final Set<Color> amberColors = amber[0]
          .lineBarsData
          .map((LineChartBarData bar) => bar.color!)
          .toSet();

      for (final LineChartBarData bar in teal[0].lineBarsData) {
        expect(amberColors, isNot(contains(bar.color)));
      }
    });
  });
}
