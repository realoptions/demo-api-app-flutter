import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:realoptions/components/CustomPadding.dart';

/// What a chart page shows for one bloc state.
///
/// The density and options pages each spelled out the same four branches -
/// nothing submitted yet, request in flight, failed, charts ready - with the
/// same widgets hanging off the end of each. Folding them into one value means
/// the placeholders and the layout are written once, in [ChartPage], and a page
/// only has to say which of its own states means what.
sealed class ChartView {
  const ChartView();
}

/// Nothing has been submitted yet, so there is nothing to plot.
class ChartEmpty extends ChartView {
  const ChartEmpty();
}

/// A request is in flight.
class ChartBusy extends ChartView {
  const ChartBusy();
}

/// The bloc reported a failure.
class ChartFailed extends ChartView {
  const ChartFailed(this.message);

  final String message;
}

/// Charts to lay out.
class ChartReady extends ChartView {
  const ChartReady(this.charts);

  final List<Widget> charts;
}

/// The responsive layout every chart page puts its charts in: one column in
/// portrait, two in landscape, each chart wrapped in the same padding.
class ChartGrid extends StatelessWidget {
  const ChartGrid({super.key, required this.charts});

  final List<Widget> charts;

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (BuildContext context, Orientation orientation) {
        return GridView.count(
          crossAxisCount: orientation == Orientation.portrait ? 1 : 2,
          children: [
            for (final Widget chart in charts) PaddingForm(child: chart),
          ],
        );
      },
    );
  }
}

/// Watches bloc [B] and renders whatever its current state resolves to.
///
/// This is the scaffold both chart pages were hand-writing: the `BlocBuilder`,
/// the three placeholders, and the grid. A page supplies [resolve] - its state
/// type mapped onto a [ChartView] - and keeps none of the surrounding shape.
class ChartPage<B extends StateStreamable<S>, S> extends StatelessWidget {
  const ChartPage({super.key, required this.resolve});

  /// Maps the bloc's current state onto something this widget can render.
  final ChartView Function(BuildContext context, S state) resolve;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<B, S>(
      builder: (BuildContext context, S state) =>
          switch (resolve(context, state)) {
        ChartBusy() => const Center(child: CircularProgressIndicator()),
        ChartFailed(:final String message) => Center(child: Text(message)),
        ChartReady(:final List<Widget> charts) => ChartGrid(charts: charts),
        ChartEmpty() => const Center(child: Text('Please submit parameters!')),
      },
    );
  }
}
