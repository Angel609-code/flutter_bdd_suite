import 'package:flutter/material.dart';
import 'package:flutter_bdd_suite/flutter_bdd_suite.dart';
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
  return stepRegExp(RegExp(r'^I fill the (.+?) field with:$'), (ctx) async {
    final (type,) = ctx.args.one<String>();
    final key = resolveKey(type);

    await ctx.tester.enterText(find.byKey(Key(key)), ctx.docString().split('\n').map((line) => line.trim()).join());
    await ctx.tester.pumpAndSettle();
  });
}

// I print table to test output:
StepDefinitionGeneric iPrintTableToTestOutput() {
  return stepRegExp(RegExp(r'^I print table to test output:$'), (ctx) async {
    // final table = ctx.table().asMap();
    // for (final row in table) {
    //   logLine('| ${row.values.join(' | ')} |');
    // }
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
