import 'package:flutter/material.dart';
import 'package:flutter_bdd_suite/utils/step_definition_generic.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _enterText(StepContext ctx, String key, String text) async {
  await ctx.tester.enterText(find.byKey(Key(key)), text);
  await ctx.tester.pumpAndSettle();
}

StepDefinitionGeneric iFillUsernameField() {
  return step('I fill the username field with {string}', (ctx) async {
    final (value,) = ctx.args.one<String>();
    await _enterText(ctx, 'username_field', value);
  });
}

StepDefinitionGeneric iFillPasswordField() {
  return step('I fill the password field with {string}', (ctx) async {
    final (value,) = ctx.args.one<String>();
    await _enterText(ctx, 'password_field', value);
  });
}

StepDefinitionGeneric iFillEmployeeNameField() {
  return step('I fill the Employee Name field with {string}', (ctx) async {
    final (value,) = ctx.args.one<String>();
    await _enterText(ctx, 'employee_name_field', value);
  });
}

StepDefinitionGeneric iFillEmployeeRoleField() {
  return step('I fill the Employee Role field with {string}', (ctx) async {
    final (value,) = ctx.args.one<String>();
    await _enterText(ctx, 'employee_role_field', value);
  });
}

StepDefinitionGeneric iFillEmployeeAgeField() {
  return step('I fill the Employee Age field with {string}', (ctx) async {
    final (value,) = ctx.args.one<String>();
    await _enterText(ctx, 'employee_age_field', value);
  });
}

StepDefinitionGeneric iFillEmployeeBioField() {
  return step('I fill the Employee Bio field with {string}', (ctx) async {
    final (value,) = ctx.args.one<String>();
    await _enterText(ctx, 'employee_bio_field', value);
  });
}

StepDefinitionGeneric iFillSearchField() {
  return step('I fill the search field with {string}', (ctx) async {
    final (value,) = ctx.args.one<String>();
    await _enterText(ctx, 'search_field', value);
  });
}

Future<void> _tapKey(StepContext ctx, String key) async {
  await ctx.tester.tap(find.byKey(Key(key)));
  await ctx.tester.pumpAndSettle();
}

Future<void> _tapText(StepContext ctx, String text) async {
  await ctx.tester.tap(find.text(text));
  await ctx.tester.pumpAndSettle();
}

StepDefinitionGeneric iTapLoginButton() {
  return step('I tap the login button', (ctx) => _tapKey(ctx, 'login_button'));
}

StepDefinitionGeneric iTapAddEmployeeButton() {
  return step(
    'I tap the add employee button',
    (ctx) => _tapKey(ctx, 'add_employee_fab'),
  );
}

StepDefinitionGeneric iTapSaveEmployeeButton() {
  return step(
    'I tap the save employee button',
    (ctx) => _tapKey(ctx, 'save_employee_button'),
  );
}

StepDefinitionGeneric iTapCancelEmployeeButton() {
  return step(
    'I tap the cancel employee button',
    (ctx) => _tapKey(ctx, 'cancel_employee_button'),
  );
}

StepDefinitionGeneric iTapDeleteConfirmButton() {
  return step(
    'I tap the delete confirm button',
    (ctx) => _tapKey(ctx, 'delete_confirm_button'),
  );
}

StepDefinitionGeneric iTapDeleteCancelButton() {
  return step(
    'I tap the delete cancel button',
    (ctx) => _tapKey(ctx, 'delete_cancel_button'),
  );
}

StepDefinitionGeneric iTapDialogsActionButton() {
  return step(
    'I tap the dialogs_action button',
    (ctx) => _tapKey(ctx, 'dialogs_action'),
  );
}

StepDefinitionGeneric iTapFilesActionButton() {
  return step(
    'I tap the files_action button',
    (ctx) => _tapKey(ctx, 'files_action'),
  );
}

StepDefinitionGeneric iTapSettingsActionButton() {
  return step(
    'I tap the settings_action button',
    (ctx) => _tapKey(ctx, 'settings_action'),
  );
}

StepDefinitionGeneric iTapNotificationsButton() {
  return step(
    'I tap the notifications button',
    (ctx) => _tapKey(ctx, 'notifications'),
  );
}

StepDefinitionGeneric iTapDarkModeButton() {
  return step('I tap the dark mode button', (ctx) => _tapKey(ctx, 'dark mode'));
}

StepDefinitionGeneric iTapNavigationActionButton() {
  return step(
    'I tap the navigation action button',
    (ctx) => _tapKey(ctx, 'navigation action'),
  );
}

StepDefinitionGeneric iTapOSBackButton() {
  return step('I tap the OS back button', (ctx) => _tapKey(ctx, 'OS back'));
}

// These use `{int}` expressions for parameterized delete/edit buttons
StepDefinitionGeneric iTapDeleteEmployeeButton() {
  return step('I tap the delete employee {int} button', (ctx) async {
    final (index,) = ctx.args.one<int>();
    await _tapKey(ctx, 'delete_employee_$index');
  });
}

StepDefinitionGeneric iTapEditEmployeeButton() {
  return step('I tap the edit employee {int} button', (ctx) async {
    final (index,) = ctx.args.one<int>();
    await _tapKey(ctx, 'edit_employee_$index');
  });
}

// These are matched by literal text value on screen
StepDefinitionGeneric iTapTextButton() {
  // Use RegExp for all text buttons to avoid making 15 step definitions,
  // but keep it clean (no big switches).
  return stepRegExp(
    RegExp(
      r'^I tap the (Show Alert Dialog|OK|Show Confirmation Dialog|Yes|Show Bottom Sheet|Share|Show Snackbar|trigger|dismiss|Import CSV|Raw View|Table View|Export CSV|View Terms & Conditions|Close) button$',
    ),
    (ctx) async {
      final (text,) = ctx.args.one<String>();
      await _tapText(ctx, text);
    },
  );
}

StepDefinitionGeneric iScrollToDeleteEmployeeButton() {
  return step('I scroll to the delete employee {int} button', (ctx) async {
    final (index,) = ctx.args.one<int>();
    await ctx.tester.ensureVisible(find.byKey(Key('delete_employee_$index')));
    await ctx.tester.pumpAndSettle();
  });
}

StepDefinitionGeneric iScrollToEditEmployeeButton() {
  return step('I scroll to the edit employee {int} button', (ctx) async {
    final (index,) = ctx.args.one<int>();
    await ctx.tester.ensureVisible(find.byKey(Key('edit_employee_$index')));
    await ctx.tester.pumpAndSettle();
  });
}
