import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyaysahayak/landing_page.dart';

void main() {
  testWidgets('LandingPage renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LandingPage()),
    );
    expect(find.text('Legal Assistance'), findsOneWidget);
  });
}
