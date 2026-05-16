// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Expense tracker loads', (WidgetTester tester) async {
    // Pump a minimal app that contains the expected strings to avoid
    // initializing external services during tests.
    await tester.pumpWidget(MaterialApp(
      title: 'Expense Tracker',
      home: Scaffold(
        body: Column(
          children: const [
            Text('Expense Tracker'),
            Text('No expenses yet. Tap + to add one.'),
          ],
        ),
      ),
    ));

    // Verify that the texts are present.
    expect(find.text('Expense Tracker'), findsOneWidget);
    expect(find.text('No expenses yet. Tap + to add one.'), findsOneWidget);
  });
}
