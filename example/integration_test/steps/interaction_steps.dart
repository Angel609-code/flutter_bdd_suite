import 'package:flutter/material.dart';
import 'package:flutter_bdd_suite/utils/step_definition_generic.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common_steps.dart';

StepDefinitionGeneric iEnterText() {
  // Use non-capturing groups `(?:enter|fill)` to simplify the callback signature.
  return step2<String, String, StepContext>(
    r'I (?:enter|fill) the (.+?)(?: field with)? {string}',
    (type, value, ctx) async {
      final key = resolveKey(type);

      await ctx.tester.enterText(find.byKey(Key(key)), value);
      await ctx.tester.pumpAndSettle();
    },
  );
}

StepDefinitionGeneric iInteractWithButton() {
  return step2<String, String, StepContext>(
    r'I (tap|scroll to) the (.+?) button',
    (action, type, ctx) async {
      final key = resolveKey(type);
      final finder = find.byKey(Key(key));

      if (action == 'scroll to') {
        await ctx.tester.ensureVisible(finder);
      } else {
        await ctx.tester.tap(finder);
      }

      await ctx.tester.pumpAndSettle();
    },
  );
}
