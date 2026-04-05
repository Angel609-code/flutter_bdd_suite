import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BddExampleApp());

    expect(find.text('Login'), findsWidgets);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
