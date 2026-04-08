import 'package:flutter/material.dart';
import 'package:example/main.dart';
import 'package:example/app_theme.dart';
import 'package:flutter_bdd_suite/utils/step_definition_generic.dart';
import 'package:flutter_bdd_suite/world/widget_tester_world.dart';
import 'package:flutter_test/flutter_test.dart';

String resolveKey(String type) {
  final map = {
    'the employee table': 'employee_table',
    'the employee dialog title': 'employee_dialog_title',
    'the delete confirm message': 'delete_confirm_message',
    'the empty employee text': 'empty_employee_text',

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
  };

  if (map.containsKey(type)) return map[type]!;

  if (type.startsWith('delete employee ')) {
    final i = type.split(' ').last;
    return 'delete_employee_$i';
  }

  if (type.startsWith('edit employee ')) {
    final i = type.split(' ').last;
    return 'edit_employee_$i';
  }

  throw Exception('Unknown element: $type');
}

StepDefinitionGeneric theApplicationIsLaunched() {
  return generic<WidgetTesterWorld>(
    r'the application is launched',
    (world) async {
      themeNotifier.value = ThemeMode.light;
      await world.tester.pumpWidget(const BddExampleApp());
      await world.tester.pumpAndSettle();
    },
  );
}

StepDefinitionGeneric iShouldSeeTextOrElement() {
  return generic4<String?, String?, String?, String?, WidgetTesterWorld>(
    r'I should (not )?see (?:multiple )?(?:(.+?) element|{string})(?: texts)?',
    (notMatch, type, text, _, world) async {
      final shouldNot = notMatch != null && notMatch.isNotEmpty;

      Finder finder;

      if (text != null && text.isNotEmpty) {
        finder = find.textContaining(text);
      } else {
        final key = resolveKey(type!);
        finder = find.byKey(Key(key));
      }

      if (shouldNot) {
        expect(finder, findsNothing);
      } else {
        expect(finder, findsWidgets);
      }
    },
  );
}

StepDefinitionGeneric theLoginUIIsVisible() {
  return generic3<String, String, String, WidgetTesterWorld>(
    r'the login (screen|form fields) (is|are) (visible|present)',
    (_, __, ___, world) async {
      expect(find.byKey(const Key('username_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
    },
  );
}

StepDefinitionGeneric theElementIsVisible() {
  return generic4<String, String?, String, String, WidgetTesterWorld>(
    r'(.+?) element(s)? (is|are) (?:visible|present|{string})',
    (type, _, __, value, world) async {
      final key = resolveKey(type);
      if (value == 'visible' || value == 'present') {
        expect(find.byKey(Key(key)), findsOneWidget);
      } else {
        expect(find.byKey(Key(key)), findsNothing);
      }
    },
  );
}

StepDefinitionGeneric iShouldReachDashboard() {
  return generic1<String?, WidgetTesterWorld>(
    r'I should (not )?reach the dashboard',
    (notMatch, world) async {
      final shouldReach = notMatch == null || notMatch.isEmpty;

      if (shouldReach) {
        expect(find.byKey(const Key('add_employee_fab')), findsOneWidget);
      } else {
        expect(find.byKey(const Key('login_button')), findsOneWidget);
      }
    },
  );
}
