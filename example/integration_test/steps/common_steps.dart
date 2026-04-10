import 'package:flutter/material.dart';
import 'package:example/main.dart';
import 'package:example/app_theme.dart';
import 'package:flutter_bdd_suite/utils/step_definition_generic.dart';
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
  return step('the application is launched', (ctx) async {
    themeNotifier.value = ThemeMode.light;
    await ctx.tester.pumpWidget(const BddExampleApp());
    await ctx.tester.pumpAndSettle();
  });
}

StepDefinitionGeneric iShouldSeeTextOrElement() {
  return stepRegExp(RegExp(r'I should (not )?see (.+)'), (ctx) async {
    final (notMatch, raw) = ctx.args.two<String?, String>();

    final shouldNot = notMatch != null && notMatch.isNotEmpty;

    Finder finder;

    final multipleMatch = RegExp(r'^multiple "([^"]*)" texts$').firstMatch(raw);

    if (multipleMatch != null) {
      final text = multipleMatch.group(1)!;
      finder = find.text(text);

      final count = int.tryParse(text);

      if (shouldNot) {
        expect(finder, findsNothing);
      } else if (count != null) {
        expect(finder, findsNWidgets(count));
      } else {
        expect(finder, findsWidgets);
      }
      return;
    }

    if (raw.startsWith('"') && raw.endsWith('"')) {
      final text = raw.substring(1, raw.length - 1);
      finder = find.textContaining(text);
    } else if (raw.endsWith(' element')) {
      final type = raw.replaceAll(' element', '');
      final key = resolveKey(type);
      finder = find.byKey(Key(key));
    } else {
      throw Exception('Invalid step format: $raw');
    }

    if (shouldNot) {
      expect(finder, findsNothing);
    } else {
      expect(finder, findsWidgets);
    }
  });
}

StepDefinitionGeneric theLoginUIIsVisible() {
  // We use non-capturing groups `(?:screen|form fields)` and `(?:is|are)`
  // to avoid passing useless words as step arguments.
  return stepRegExp(
    RegExp(r'the login (?:screen|form fields) (?:is|are) (?:visible|present)'),
    (ctx) async {
      expect(find.byKey(const Key('username_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
    },
  );
}

StepDefinitionGeneric theElementIsVisible() {
  return stepRegExp(
    // This regex supports BOTH:
    //   is visible
    //   is "visible"
    //
    // Breakdown:
    // (.+?)                  → Captures the element type (e.g. "employee dialog title")
    // element(?:s)?          → Matches "element" or "elements"
    // (?:is|are)             → Matches "is" or "are"
    // "?([^"]+)"?            → Captures the state, with OPTIONAL quotes
    //
    // Key idea:
    // "?        → optional opening quote
    // ([^"]+)   → capture ANY text that is NOT a quote
    // "?        → optional closing quote
    //
    // This means BOTH of these produce the SAME captured value:
    //   visible   → stateRaw = "visible"
    //   "visible" → stateRaw = "visible"
    //
    RegExp(r'(.+?) element(?:s)? (?:is|are) "?([^"]+)"?'),
    (ctx) async {
      // We always get exactly TWO values:
      // type     → "employee dialog title"
      // stateRaw → "visible" OR "hidden" (quotes already stripped by regex)
      final (type, stateRaw) = ctx.args.two<String, String>();

      // Normalize just in case (defensive programming)
      final state = stateRaw.toLowerCase().trim();

      final key = resolveKey(type);
      final finder = find.byKey(Key(key));

      // Interpret the meaning of the state
      switch (state) {
        case 'visible':
        case 'present':
          // Widget must exist in the widget tree
          expect(finder, findsOneWidget);
          break;

        case 'hidden':
          // Widget must NOT exist in the widget tree
          expect(finder, findsNothing);
          break;

        default:
          throw Exception('Invalid state: $state');
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
