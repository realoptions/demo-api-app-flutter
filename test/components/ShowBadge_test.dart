// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:badges/badges.dart';
import 'package:realoptions/components/ShowBadge.dart';

void main() {
  testWidgets('Shows badge if showBadge is true', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: ShowBadge(icon: Icon(Icons.event), showBadge: true)));
    expect(find.byIcon(Icons.event), findsOneWidget);
    expect(find.byType(Badge), findsOneWidget);
  });
  testWidgets('Shows badge if showBadge is false', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: ShowBadge(icon: Icon(Icons.event), showBadge: false)));
    expect(find.byIcon(Icons.event), findsOneWidget);
    expect(find.byType(Badge), findsNothing);
  });
}
