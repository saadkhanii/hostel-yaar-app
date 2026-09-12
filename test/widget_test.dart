// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hostel_yaar/main.dart';

void main() {
  testWidgets('App builds and provides a MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Let any startup timers (e.g. splash screen navigation) run
    await tester.pump(const Duration(seconds: 3));

    // The app should contain a MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);

    // Optional: initial route is splash; ensure navigator exists
    expect(find.byType(Navigator), findsOneWidget);
  });
}
