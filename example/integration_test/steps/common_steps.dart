import 'package:flutter/material.dart';
import 'package:example/main.dart';
import 'package:example/app_theme.dart';
import 'package:flutter_bdd_suite/utils/step_definition_generic.dart';
import 'package:flutter_test/flutter_test.dart';

String resolveKey(String type) {
  final map = {
    'employee table': 'employee_table',
    'employee table headers': 'employee_table',
    'employee dialog title': 'employee_dialog_title',
    'delete confirm message': 'delete_confirm_message',
    'empty employee text': 'empty_employee_text',

    'username': 'username_field',
    'password': 'password_field',

    'employee name': 'employee_name_field',
    'employee role': 'employee_role_field',
    'employee age': 'employee_age_field',
    'employee bio': 'employee_bio_field',
    'search': 'search_field',

    'login': 'login_button',
    'add employee': 'add_employee_fab',
    'save employee': 'save_employee_button',
    'cancel employee': 'cancel_employee_button',
    'delete confirm': 'delete_confirm_button',
    'delete cancel': 'delete_cancel_button',
    'cancel': 'cancel_button',

    'settings action': 'settings_action',
    'files action': 'files_action',
    'dialogs action': 'dialogs_action',

    'show alert dialog': 'show_alert_dialog_button',
    'show bottom sheet': 'show_bottom_sheet_button',
    'show confirmation dialog': 'show_confirmation_dialog_button',
    'show snackbar': 'show_snackbar_button',
    'trigger dialog': 'trigger_dialog_button',
    'close icon': 'close_icon_button',
    'import csv': 'import_csv_button',
    'raw view': 'raw_view_button',
    'table view': 'table_view_button',
    'export csv': 'export_csv_button',
    'view terms': 'view_terms_button',
    'close terms': 'close_terms_button',
    'back': 'back_button',
    'ok': 'ok_button',
    'yes': 'yes_button',
    'share bottom sheet option': 'share_bottom_sheet_option',

    'notifications switch': 'notifications_switch',
    'dark mode checkbox': 'dark_mode_checkbox',
    'volume slider': 'volume_slider',

    'login form fields': 'username_field',
};


  if (map.containsKey(type)) return map[type]!;

  if (type == 'delete for "Alice Johnson"') return 'delete_employee_0';
  if (type == 'edit for "Bob Martinez"') return 'edit_employee_1';
  if (type == 'edit for "Eve Torres"') return 'edit_employee_3';
  if (type == 'delete for "Eve Torres"') return 'delete_employee_3';


  throw Exception('Unknown element: \$type');
}

StepDefinitionGeneric theApplicationIsLaunched() {
  return step('the application is launched', (ctx) async {
    themeNotifier.value = ThemeMode.light;
    await ctx.tester.pumpWidget(const BddExampleApp());
    await ctx.tester.pumpAndSettle();
  });
}


StepDefinitionGeneric theElementShouldBeVisible() {
  return stepRegExp(
    RegExp(r'^the (.+?) should (not )?be visible$'),
    (ctx) async {
      final (type, notMatch) = ctx.args.two<String, String?>();
      final shouldNot = notMatch != null && notMatch.isNotEmpty;

      final key = resolveKey(type);
      final finder = find.byKey(Key(key));

      if (shouldNot) {
        expect(finder, findsNothing);
      } else {
        expect(finder, findsWidgets);
      }
    },
  );
}

StepDefinitionGeneric iShouldSeeText() {
  return stepRegExp(
    RegExp(r'^I should (not )?see "([^"]+)"$'),
    (ctx) async {
      final (notMatch, textRaw) = ctx.args.two<String?, String>();
      final shouldNot = notMatch != null && notMatch.isNotEmpty;

      final finder = find.textContaining(textRaw);

      if (shouldNot) {
        expect(finder, findsNothing);
      } else {
        expect(finder, findsWidgets);
      }
    },
  );
}

StepDefinitionGeneric iShouldSeeMultipleTexts() {
  return stepRegExp(
    RegExp(r'^I should see multiple "([^"]+)" texts$'),
    (ctx) async {
      final (textRaw,) = ctx.args.one<String>();
      final count = int.tryParse(textRaw);

      if (count != null) {
        expect(find.text(textRaw), findsNWidgets(count));
      } else {
        expect(find.text(textRaw), findsWidgets);
      }
    },
  );
}


StepDefinitionGeneric iShouldReachDashboard() {
  return stepRegExp(RegExp(r'I should (not )?reach the dashboard'), (
    ctx,
  ) async {
    final (notMatch,) = ctx.args.one<String?>();
    final shouldReach = notMatch == null || notMatch.isEmpty;

    if (shouldReach) {
      expect(find.byKey(const Key('add_employee_fab')), findsOneWidget);
    } else {
      expect(find.byKey(const Key('login_button')), findsOneWidget);
    }
  });
}
