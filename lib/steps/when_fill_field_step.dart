import 'package:flutter/material.dart';
import 'package:flutter_bdd_suite/utils/step_definition_generic.dart';
import 'package:flutter_test/flutter_test.dart';

/// Creates a step definition that enters [value] into the widget whose key is [key].
///
/// This uses `generic2` to define a step with two `{string}` parameters:
/// 1. The widget's key (as a string)
/// 2. The text to enter (as a string)
///
/// Pattern example:
///   Then I fill the "email" field with "bob@gmail.com"
///   Then I fill the "name" field with "Woody Johnson"
///
/// How to build your own step:
/// 1. Choose the number of captures and call the corresponding `genericN`:
///    - `generic1<T, W>(pattern, (arg1, world) async { … })`
///    - `generic2<T1, T2, W>(pattern, (arg1, arg2, world) async { … })`
///    - … up to `generic6`.
/// 2. In the pattern, use `{string}` wherever you expect a quoted string argument.
/// 3. To access an attached data table or doc-string, use `world.table` or `world.docString`:
///    ```dart
///    generic('the following exist', (world) async {
///      final table = world.table;
///      if (table != null) { ... }
///    });
///    ```
///
/// Returns a `StepDefinitionGeneric` that the runner can register.
StepDefinitionGeneric whenFillFieldStep() {
  return step('I fill the {string} field with {string}', (ctx) async {
    final (key, value) = ctx.args.two<String, String>();
    // Find the widget by its ValueKey.
    final finder = find.byKey(ValueKey(key));

    // Verify that exactly one widget matches.
    expect(finder, findsOneWidget);

    // Enter the provided text into the widget.
    await ctx.tester.enterText(finder, value);

    // Allow the UI to settle after text entry.
    // Uses the global timeout from IntegrationTestConfig.
    await ctx.tester.pumpAndSettle();
  });
}
