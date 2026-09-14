import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:realoptions/components/ShowBadge.dart';

void main() {
  testWidgets('draws the dot over the icon when showBadge is true',
      (WidgetTester tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: ShowBadge(icon: Icon(Icons.event), showBadge: true),
    ));
    expect(find.byIcon(Icons.event), findsOneWidget);
    final Badge badge = tester.widget(find.byType(Badge));
    expect(badge.isLabelVisible, isTrue);
  });

  testWidgets('hides the dot when showBadge is false, keeping the icon',
      (WidgetTester tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: ShowBadge(icon: Icon(Icons.event), showBadge: false),
    ));
    expect(find.byIcon(Icons.event), findsOneWidget);
    // The Badge widget stays mounted either way - it is the label that toggles,
    // not the widget - so the assertion is on visibility rather than presence.
    final Badge badge = tester.widget(find.byType(Badge));
    expect(badge.isLabelVisible, isFalse);
  });
}
