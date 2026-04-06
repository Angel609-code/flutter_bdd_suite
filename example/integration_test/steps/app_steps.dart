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

// Reusable element key mapper for app steps
String getElementKey(String type) {
  final Map<String, String> elementMappings = {
    'employee table': 'employee_table',
    'employee dialog title': 'employee_dialog_title',
    'delete confirm message': 'delete_confirm_message',
    'empty employee text': 'empty_employee_text',
  };

  final dynamic elementKey = elementMappings[type];

  if (elementKey == null) {
    throw Exception('Element mapping "$type" is not defined.');
  }
  return elementKey;
}

StepDefinitionGeneric iShouldSeeElement() {
  return generic1<String, WidgetTesterWorld>(
    r'I should see the (.+?)(?: element)?', (type, world) async {
      final key = getElementKey(type);
      expect(find.byKey(Key(key)), findsOneWidget);
    },
  );
}

StepDefinitionGeneric iShouldNotSeeElement() {
  return generic1<String, WidgetTesterWorld>(
    r'I should not see the (.+?)(?: element)?', (type, world) async {
      final key = getElementKey(type);
      expect(find.byKey(Key(key)), findsNothing);
    },
  );
}

StepDefinitionGeneric iShouldNotSee() {
  return generic1<String, WidgetTesterWorld>(
    r'I should not see {string}', (value, world) async {
      expect(find.textContaining(value), findsNothing);
    },
  );
}

StepDefinitionGeneric iShouldSeeMultipleTexts() {
  return generic1<String, WidgetTesterWorld>(
    r'I should see multiple {string} texts', (value, world) async {
      expect(find.textContaining(value), findsWidgets);
    },
  );
}

StepDefinitionGeneric iScrollToElement() {
  return generic1<String, WidgetTesterWorld>(
    r'I scroll to the (.+?) button', (type, world) async {
      String? buttonKey;
      if (type.startsWith('delete employee ')) {
        final index = type.split(' ').last;
        buttonKey = 'delete_employee_$index';
      } else if (type.startsWith('edit employee ')) {
        final index = type.split(' ').last;
        buttonKey = 'edit_employee_$index';
      } else {
        throw Exception('Scroll target mapping "$type" is not defined.');
      }

      await world.tester.ensureVisible(find.byKey(Key(buttonKey)));
      await world.tester.pumpAndSettle();
    },
  );
}

StepDefinitionGeneric theElementIs() {
  return generic2<String, String, WidgetTesterWorld>(
    r'the (.+?)(?: element)? is {string}', (type, state, world) async {
      final key = getElementKey(type);
      if (state == 'visible') {
        expect(find.byKey(Key(key)), findsOneWidget);
      } else if (state == 'hidden') {
        expect(find.byKey(Key(key)), findsNothing);
      } else {
        throw Exception('Unknown element state: $state');
      }
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
