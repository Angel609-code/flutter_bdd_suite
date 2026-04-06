import 'package:flutter/material.dart';
import 'package:example/main.dart';
import 'package:example/app_theme.dart';
import 'package:flutter_bdd_suite/utils/step_definition_generic.dart';
import 'package:flutter_bdd_suite/world/widget_tester_world.dart';
import 'package:flutter_test/flutter_test.dart';

StepDefinitionGeneric theApplicationIsLaunched() {
  return generic<WidgetTesterWorld>(
    r'the application is launched', (world) async {
      themeNotifier.value = ThemeMode.light;
      await world.tester.pumpWidget(const BddExampleApp());
      await world.tester.pumpAndSettle();
    },
  );
}

StepDefinitionGeneric theLoginScreenIsVisible() {
  return generic<WidgetTesterWorld>(
    r'the login screen is visible', (world) async {
      expect(find.byKey(const Key('username_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      expect(find.byKey(const Key('login_button')), findsOneWidget);
    },
  );
}

StepDefinitionGeneric theLoginFieldsArePresent() {
  return generic<WidgetTesterWorld>(
    r'the login form fields are present', (world) async {
      expect(find.byKey(const Key('username_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
    },
  );
}

StepDefinitionGeneric iShouldReachDashboard() {
  return generic1<String?, WidgetTesterWorld>(
    r'I should (not )?reach the dashboard', (notMatch, world) async {
      final shouldReach = notMatch == null || notMatch.isEmpty;

      if (shouldReach) {
        expect(find.byKey(const Key('add_employee_fab')), findsOneWidget);
      } else {
        expect(find.byKey(const Key('login_button')), findsOneWidget);
      }
    },
  );
}
