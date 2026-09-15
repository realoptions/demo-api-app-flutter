import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:realoptions/components/ChartPage.dart';
import 'package:realoptions/components/CustomPadding.dart';

/// A cubit whose state *is* the view, so [ChartPage]'s resolver is the
/// identity and the scaffold can be driven directly without inventing a
/// throwaway bloc state hierarchy to map.
class _ViewCubit extends Cubit<ChartView> {
  _ViewCubit(super.initial);
}

Widget shell(ChartView view) => MaterialApp(
      home: Scaffold(
        body: BlocProvider<_ViewCubit>(
          create: (_) => _ViewCubit(view),
          child: ChartPage<_ViewCubit, ChartView>(
            resolve: (BuildContext context, ChartView view) => view,
          ),
        ),
      ),
    );

/// Charts with distinct keys, so the grid cannot collapse them into one.
List<Widget> twoCharts() => [
      Container(key: UniqueKey(), height: 12),
      Container(key: UniqueKey(), height: 12),
    ];

int crossAxisCount(WidgetTester tester) {
  final GridView grid = tester.widget<GridView>(find.byType(GridView));
  return (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
      .crossAxisCount;
}

void main() {
  group('ChartPage', () {
    testWidgets('empty renders the submit prompt', (tester) async {
      await tester.pumpWidget(shell(const ChartEmpty()));
      expect(find.text('Please submit parameters!'), findsOneWidget);
      expect(find.byType(GridView), findsNothing);
    });

    testWidgets('busy renders a spinner', (tester) async {
      await tester.pumpWidget(shell(const ChartBusy()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(GridView), findsNothing);
    });

    testWidgets('failed renders the message the bloc reported', (tester) async {
      await tester.pumpWidget(shell(const ChartFailed('boom')));
      expect(find.text('boom'), findsOneWidget);
      expect(find.byType(GridView), findsNothing);
    });

    testWidgets('ready lays its charts out in the grid', (tester) async {
      await tester.pumpWidget(shell(ChartReady(twoCharts())));
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(PaddingForm), findsNWidgets(2));
    });

    testWidgets('it follows the cubit as the view changes', (tester) async {
      final _ViewCubit cubit = _ViewCubit(const ChartEmpty());
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BlocProvider<_ViewCubit>(
            create: (_) => cubit,
            child: ChartPage<_ViewCubit, ChartView>(
              resolve: (BuildContext context, ChartView view) => view,
            ),
          ),
        ),
      ));
      expect(find.text('Please submit parameters!'), findsOneWidget);

      cubit.emit(const ChartBusy());
      // `pump()`, not `pumpAndSettle()`: the busy state's spinner animates
      // forever, so settle never returns.
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Please submit parameters!'), findsNothing);
    });
  });

  group('ChartGrid', () {
    testWidgets('one column in portrait, two in landscape', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ChartGrid(charts: twoCharts())),
      ));
      expect(crossAxisCount(tester), 1);

      tester.view.physicalSize = const Size(800, 400);
      await tester.pumpAndSettle();
      expect(crossAxisCount(tester), 2);
    });
  });
}
