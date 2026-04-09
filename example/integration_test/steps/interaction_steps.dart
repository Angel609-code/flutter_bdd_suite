import 'package:flutter/material.dart';
import 'package:flutter_bdd_suite/utils/step_definition_generic.dart';
import 'package:flutter_bdd_suite/world/widget_tester_world.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common_steps.dart';

StepDefinitionGeneric iEnterText() {
  return generic4<String, String, String, String, WidgetTesterWorld>(
    r'I (enter|fill) the (.+?)(?: field with)? {string}',
    (action, type, suffix, value, world) async {
      final key = resolveKey(type);

      await world.tester.enterText(find.byKey(Key(key)), value);
      await world.tester.pumpAndSettle();
    },
  );
}

StepDefinitionGeneric iInteractWithButton() {
  return generic2<String, String, WidgetTesterWorld>(
    r'I (tap|scroll to) the (.+?) button',
    (action, type, world) async {
      final key = resolveKey(type);
      final finder = find.byKey(Key(key));

      if (action == 'scroll to') {
        await world.tester.ensureVisible(finder);
      } else {
        await world.tester.tap(finder);
      }

      await world.tester.pumpAndSettle();
    },
  );
}
