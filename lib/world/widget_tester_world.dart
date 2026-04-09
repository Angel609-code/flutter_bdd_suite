import 'dart:collection';
import 'package:flutter_bdd_suite/models/gherkin_table_model.dart';
import 'package:flutter_bdd_suite/models/step_multiline_arg.dart';
import 'package:flutter_bdd_suite/world/test_world.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// A default implementation of [TestWorld] specifically tailored for Flutter widget testing.
///
/// The `WidgetTesterWorld` holds the current `WidgetTester` and `IntegrationTestWidgetsFlutterBinding`
/// required to interact with the Flutter widget tree during test execution.
///
/// It also acts as a state container, allowing data to be shared between different steps
/// in the same scenario using the attachments map ([setAttachment] and [getAttachment]).
class WidgetTesterWorld implements TestWorld {
  late final IntegrationTestWidgetsFlutterBinding _binding;
  WidgetTester? _tester;

  final Map<String, Object> _attachments = HashMap();

  StepMultilineArg? _multilineArg;

  @override
  Future<void> setTester(WidgetTester tester) async {
    _tester = tester;
  }

  @override
  Future<void> setBinding(IntegrationTestWidgetsFlutterBinding binding) async {
    _binding = binding;
  }

  @override
  WidgetTester get tester {
    if (_tester == null) {
      throw StateError(
        'WidgetTester has not been initialized yet. This usually happens when '
        'accessing "world.tester" inside a hook (like "onBeforeAll" or '
        '"onBeforeScenario") before the Flutter test runner has started the '
        'testWidgets() execution. Use "world.testerOrNull" if you need to perform '
        'safety checks in early lifecycle hooks.',
      );
    }
    return _tester!;
  }

  @override
  WidgetTester? get testerOrNull => _tester;

  @override
  IntegrationTestWidgetsFlutterBinding get binding => _binding;

  @override
  StepMultilineArg? get multilineArg => _multilineArg;

  @override
  void setMultilineArg(StepMultilineArg? arg) {
    _multilineArg = arg;
  }

  @override
  void setAttachment<T>(String key, T value) {
    _attachments[key] = value as Object;
  }

  @override
  T? getAttachment<T>(String key) {
    final value = _attachments[key];
    if (value is T) return value;
    return null;
  }
}

/// Convenience accessors for [TestWorld] to easily extract tables and doc-strings.
extension TestWorldMultilineX on TestWorld {
  /// Returns the [GherkinTable] attached to the current step, or `null` if none.
  GherkinTable? get table => multilineArg.table;

  /// Returns the doc-string content attached to the current step, or `null` if none.
  String? get docString => multilineArg.docString;
}
