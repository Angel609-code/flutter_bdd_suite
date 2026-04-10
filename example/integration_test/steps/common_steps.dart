import 'package:flutter/material.dart';
import 'package:example/main.dart';
import 'package:example/app_theme.dart';
import 'package:flutter_bdd_suite/utils/step_definition_generic.dart';
import 'package:flutter_test/flutter_test.dart';

StepDefinitionGeneric theApplicationIsLaunched() {
  return step('the application is launched', (ctx) async {
    themeNotifier.value = ThemeMode.light;
    await ctx.tester.pumpWidget(const BddExampleApp());
    await ctx.tester.pumpAndSettle();
  });
}

Future<void> expectTextVisible(String text) async {
  expect(find.textContaining(text), findsWidgets);
}

Future<void> expectTextHidden(String text) async {
  expect(find.textContaining(text), findsNothing);
}

Future<void> expectElementVisible(String key) async {
  expect(find.byKey(Key(key)), findsOneWidget);
}

Future<void> expectElementHidden(String key) async {
  expect(find.byKey(Key(key)), findsNothing);
}

StepDefinitionGeneric iShouldSeeText() {
  return step('I should see {string}', (ctx) async {
    final (text,) = ctx.args.one<String>();
    await expectTextVisible(text);
  });
}

StepDefinitionGeneric iShouldNotSeeText() {
  return step('I should not see {string}', (ctx) async {
    final (text,) = ctx.args.one<String>();
    await expectTextHidden(text);
  });
}

StepDefinitionGeneric iShouldSeeMultipleTexts() {
  return step('I should see multiple {int} texts', (ctx) async {
    final (count,) = ctx.args.one<int>();
    expect(find.text(count.toString()), findsWidgets);
  });
}

StepDefinitionGeneric iShouldSeeMultipleSpecificTexts() {
  return step('I should see multiple {int} {string} texts', (ctx) async {
    final (count, text) = ctx.args.two<int, String>();
    expect(find.textContaining(text), findsNWidgets(count));
  });
}

StepDefinitionGeneric theLoginScreenIsVisible() {
  return step('the login screen is visible', (ctx) async {
    await expectElementVisible('username_field');
    await expectElementVisible('password_field');
  });
}

StepDefinitionGeneric theLoginButtonIsVisible() {
  return step('the login button is visible', (ctx) async {
    await expectElementVisible('login_button');
  });
}

StepDefinitionGeneric theAddEmployeeButtonIsVisible() {
  return step('the add employee button is visible', (ctx) async {
    await expectElementVisible('add_employee_fab');
  });
}

StepDefinitionGeneric theUsernameFieldIsVisible() {
  return step('the username field is visible', (ctx) async {
    await expectElementVisible('username_field');
  });
}

StepDefinitionGeneric thePasswordFieldIsVisible() {
  return step('the password field is visible', (ctx) async {
    await expectElementVisible('password_field');
  });
}

StepDefinitionGeneric theEmployeeTableIsVisible() {
  return step('the employee table is visible', (ctx) async {
    await expectElementVisible('employee_table');
  });
}

StepDefinitionGeneric theEmployeeDialogTitleIsVisible() {
  return step('the employee dialog title is visible', (ctx) async {
    await expectElementVisible('employee_dialog_title');
  });
}

StepDefinitionGeneric theEmployeeDialogTitleIsHidden() {
  return step('the employee dialog title is hidden', (ctx) async {
    await expectElementHidden('employee_dialog_title');
  });
}

StepDefinitionGeneric theEmployeeDialogTitleIsState() {
  return step('the employee dialog title is {string}', (ctx) async {
    final (state,) = ctx.args.one<String>();
    if (state == 'visible') {
      await expectElementVisible('employee_dialog_title');
    } else {
      await expectElementHidden('employee_dialog_title');
    }
  });
}

StepDefinitionGeneric theDeleteConfirmMessageIsVisible() {
  return step('the delete confirm message is visible', (ctx) async {
    await expectElementVisible('delete_confirm_message');
  });
}

StepDefinitionGeneric theDeleteConfirmMessageIsHidden() {
  return step('the delete confirm message is hidden', (ctx) async {
    await expectElementHidden('delete_confirm_message');
  });
}

StepDefinitionGeneric theEmptyEmployeeTextIsVisible() {
  return step('the empty employee text is visible', (ctx) async {
    await expectElementVisible('empty_employee_text');
  });
}

StepDefinitionGeneric theCsvTableIsVisible() {
  return step('the csv table is visible', (ctx) async {
    await expectElementVisible('csv_table');
  });
}

StepDefinitionGeneric theCsvTableIsHidden() {
  return step('the csv table is hidden', (ctx) async {
    await expectElementHidden('csv_table');
  });
}

StepDefinitionGeneric theRawCsvIsHidden() {
  return step('the raw csv is hidden', (ctx) async {
    await expectElementHidden('raw_csv');
  });
}

StepDefinitionGeneric theNotificationsSwitchIsVisible() {
  return step('the notifications switch is visible', (ctx) async {
    await expectElementVisible('notifications');
  });
}

StepDefinitionGeneric theNotificationsSwitchIsState() {
  return step('the notifications switch is {string}', (ctx) async {
    final (state,) = ctx.args.one<String>();
    final finder = find.byKey(const Key('notifications'));
    final Switch switchWidget = ctx.tester.widget(finder) as Switch;
    expect(switchWidget.value.toString(), state);
  });
}

StepDefinitionGeneric theDarkModeCheckboxIsVisible() {
  return step('the dark mode checkbox is visible', (ctx) async {
    await expectElementVisible('dark mode');
  });
}

StepDefinitionGeneric theDarkModeCheckboxIsState() {
  return step('the dark mode checkbox is {string}', (ctx) async {
    final (state,) = ctx.args.one<String>();
    final finder = find.byKey(const Key('dark mode'));
    final Checkbox checkboxWidget = ctx.tester.widget(finder) as Checkbox;
    expect(checkboxWidget.value.toString(), state);
  });
}

StepDefinitionGeneric theVolumeSliderIsVisible() {
  return step('the volume slider is visible', (ctx) async {
    await expectElementVisible('volume_slider');
  });
}

StepDefinitionGeneric theTermsTextIsVisible() {
  return step('the terms text is visible', (ctx) async {
    await expectElementVisible('terms_text');
  });
}

StepDefinitionGeneric iShouldReachDashboard() {
  return stepRegExp(RegExp(r'^I (should |should not )reach the dashboard$'), (
    ctx,
  ) async {
    final (match,) = ctx.args.one<String>();
    if (match.trim() == 'should') {
      await expectElementVisible('add_employee_fab');
    } else {
      await expectElementVisible('login_button');
    }
  });
}
