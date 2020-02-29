import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/blocs/bloc_provider.dart';
import 'package:realoptions/blocs/select_model_bloc.dart';
import 'package:realoptions/components/OptionsAppBar.dart';

void main() {
  testWidgets('AppBar displays with no inputs', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Material(
            child: BlocProvider<SelectModelBloc>(
                bloc: SelectModelBloc(),
                child: Scaffold(
                    appBar: OptionsAppBar(
                        choices: modelChoices, title: "SomeTitle"))))));
    await tester.pumpAndSettle();
    expect(find.text("SomeTitle: Heston"), findsOneWidget);
    expect(find.text("SomeTitle: CGMY"), findsNothing);
  });
  testWidgets('AppBar selection works', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Material(
            child: BlocProvider<SelectModelBloc>(
                bloc: SelectModelBloc(),
                child: Scaffold(
                    appBar: OptionsAppBar(
                        choices: modelChoices, title: "SomeTitle"))))));
    await tester.pumpAndSettle();
    expect(find.text("SomeTitle: Heston"), findsOneWidget);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text("CGMY"), findsOneWidget);
    await tester.tap(find.text("CGMY"));
    await tester.pumpAndSettle();
    expect(find.text("SomeTitle: CGMY"), findsOneWidget);
    expect(find.text("CGMY"), findsNothing);
  });
  testWidgets('AppBar api key works', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Material(
            child: BlocProvider<SelectModelBloc>(
                bloc: SelectModelBloc(),
                child: Scaffold(
                    appBar: OptionsAppBar(
                        choices: modelChoices, title: "SomeTitle"))))));
    await tester.pumpAndSettle();
    expect(find.text("SomeTitle: Heston"), findsOneWidget);
    await tester.tap(find.byIcon(Icons.lock));
    await tester.pumpAndSettle();
    expect(find.text("somekey"), findsOneWidget); //apikey
    expect(find.text("CANCEL"), findsOneWidget);
    await tester.tap(find.text("CANCEL"));
    await tester.pumpAndSettle();
    expect(find.text("CANCEL"), findsNothing);
  });
  testWidgets('AppBar api key works when changing',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Material(
            child: BlocProvider<SelectModelBloc>(
                bloc: SelectModelBloc(),
                child: Scaffold(
                    appBar: OptionsAppBar(
                        choices: modelChoices, title: "SomeTitle"))))));
    await tester.pumpAndSettle();
    expect(find.text("SomeTitle: Heston"), findsOneWidget);
    await tester.tap(find.byIcon(Icons.lock));
    await tester.pumpAndSettle();
    expect(find.text("somekey"), findsOneWidget); //apikey
    expect(find.text("CANCEL"), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), "new api key");
    await tester.tap(find.text("SAVE"));
    await tester.pumpAndSettle();
    expect(find.text("CANCEL"), findsNothing);
    await tester.tap(find.byIcon(Icons.lock));
    await tester.pumpAndSettle();
    expect(find.text("new api key"), findsOneWidget); //new apikey
  });
}
