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
    r'I fill the {string} field with {string}', (fieldKey, value, world) async {
      await world.tester.enterText(find.byKey(Key(fieldKey)), value);
      await world.tester.pump();
    },
  );
}

StepDefinitionGeneric iTapButton() {
  return generic1<String, WidgetTesterWorld>(
    r'I tap the (.+?) button', (type, world) async {
      final Map<String, String> inputType = {
        'login': 'login_button',
      };

      final dynamic inputTypeKey = inputType[type];

      if (inputTypeKey == null) {
        throw Exception('Input type "$type" is not defined in the step definition.');
      }

      await world.tester.tap(find.byKey(Key(inputTypeKey)));
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
