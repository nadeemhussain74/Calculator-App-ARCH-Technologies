import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calculator_app/main.dart';

void main() {
  testWidgets('Show Advanced toggle displays advanced buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(SimpleCalculator());

    // Advanced button 'sin(' should not be visible initially
    expect(find.text('sin('), findsNothing);

    // Tap the 'Show Advanced' toggle
    await tester.tap(find.text('Show Advanced'));
    await tester.pump();

    // Now 'sin(' should be visible
    expect(find.text('sin('), findsOneWidget);

    // Toggle should now say 'Back to Basic'
    expect(find.text('Back to Basic'), findsOneWidget);

    // Tap 'Back to Basic'
    await tester.tap(find.text('Back to Basic'));
    await tester.pump();

    // Advanced buttons should be hidden again
    expect(find.text('sin('), findsNothing);
    expect(find.text('Show Advanced'), findsOneWidget);
  });
}
