import 'package:flutter/material.dart';
import 'package:flutter_bdd_suite/utils/step_definition_generic.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common_steps.dart';

StepDefinitionGeneric iEnterText() {
  // Use non-capturing groups `(?:enter|fill)` to simplify the callback signature.
  return stepRegExp(RegExp(r'^I fill the (.+?) field with \"([^\"]*)\"$'), (
    ctx,
  ) async {
    final (type, value) = ctx.args.two<String, String>();
    final key = resolveKey(type);

    await ctx.tester.enterText(find.byKey(Key(key)), value);
    await ctx.tester.pumpAndSettle();
  });
}

StepDefinitionGeneric iEnterTextDocString() {
  // Use non-capturing groups `(?:enter|fill)` to simplify the callback signature.
  return stepRegExp(RegExp(r'^I fill the (.+?) field with$'), (
    ctx,
  ) async {
    print('ctx.args: ${ctx.args.debugSource.toString()}');
    print('ctx.args: ${ctx.args.toString()}');
    print('${ctx.docString}');
  });
}

StepDefinitionGeneric iInteractWithButton() {
  return stepRegExp(RegExp(r'^I tap the (.+?) button(?: for "([^"]+)")?$'), (
    ctx,
  ) async {
    final (type, name) = ctx.args.two<String, String?>();

    final String elementKey =
        (name != null && name.isNotEmpty) ? '$type for "$name"' : type;

    final key = resolveKey(elementKey);
    final finder = find.byKey(Key(key));

    await ctx.tester.tap(finder);

    await ctx.tester.pumpAndSettle();
  });
}
