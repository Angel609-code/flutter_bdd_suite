import 'package:flutter/material.dart';
import 'package:flutter_bdd_suite/utils/step_definition_generic.dart';
import 'package:flutter_bdd_suite/world/widget_tester_world.dart';
import 'package:flutter_test/flutter_test.dart';

StepDefinitionGeneric iEnterValueInField() {
  return generic2<String, String, WidgetTesterWorld>(
    r'I enter the (.+?) {string}', (type, value, world) async {
      final Map<String, String> inputType = {
        'username': 'username_field',
        'password': 'password_field',
      };

      final dynamic inputTypeKey = inputType[type];

      if (inputTypeKey == null) {
        throw Exception('Input type "$type" is not defined in the step definition.');
      }

      await world.tester.enterText(find.byKey(Key(inputTypeKey)), value);
      await world.tester.pump();
    },
  );
}

StepDefinitionGeneric iFillField() {
  return generic2<String, String, WidgetTesterWorld>(
    r'I fill the (.+?) field with {string}', (type, value, world) async {
      final Map<String, String> fieldMappings = {
        'employee name': 'employee_name_field',
        'employee role': 'employee_role_field',
        'employee age': 'employee_age_field',
        'employee bio': 'employee_bio_field',
        'search': 'search_field',
      };

      final dynamic fieldKey = fieldMappings[type];

      if (fieldKey == null) {
        throw Exception('Field mapping "$type" is not defined in the step definition.');
      }

      await world.tester.enterText(find.byKey(Key(fieldKey)), value);
      await world.tester.pump();
    },
  );
}

StepDefinitionGeneric iTapButton() {
  return generic1<String, WidgetTesterWorld>(
    r'I tap the (.+?) button', (type, world) async {
      final Map<String, String> buttonMappings = {
        'login': 'login_button',
        'add employee': 'add_employee_fab',
        'save employee': 'save_employee_button',
        'cancel employee': 'cancel_employee_button',
        'delete confirm': 'delete_confirm_button',
        'delete cancel': 'delete_cancel_button',
      };

      String? buttonKey = buttonMappings[type];

      // Handle dynamic keys like 'delete employee 0' or 'edit employee 1'
      if (buttonKey == null) {
        if (type.startsWith('delete employee ')) {
          final index = type.split(' ').last;
          buttonKey = 'delete_employee_$index';
        } else if (type.startsWith('edit employee ')) {
          final index = type.split(' ').last;
          buttonKey = 'edit_employee_$index';
        } else {
          throw Exception('Button mapping "$type" is not defined in the step definition.');
        }
      }

      await world.tester.tap(find.byKey(Key(buttonKey)));
      await world.tester.pumpAndSettle();
    },
  );
}

StepDefinitionGeneric iShouldSee() {
  return generic1<String, WidgetTesterWorld>(
    r'I should see {string}', (value, world) async {
      expect(find.textContaining(value), findsOneWidget);
    },
  );
}
