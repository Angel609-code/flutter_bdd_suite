import 'dart:collection';
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
  late WidgetTester _tester;

  final Map<String, Object> _attachments = HashMap();

  @override
  Future<void> setTester(WidgetTester tester) async {
    _tester = tester;
  }

  @override
  Future<void> setBinding(IntegrationTestWidgetsFlutterBinding binding) async {
    _binding = binding;
  }

  /// The [WidgetTester] instance used to pump frames, find widgets, and simulate user interactions.
  @override
  WidgetTester get tester => _tester;

  /// The integration test binding.
  @override
  IntegrationTestWidgetsFlutterBinding get binding => _binding;

  /// Stores a value in the world context for later retrieval by other steps.
  @override
  void setAttachment<T>(String key, T value) {
    _attachments[key] = value as Object;
  }

  /// Retrieves a previously stored value from the world context.
  @override
  T? getAttachment<T>(String key) {
    final value = _attachments[key];
    if (value is T) return value;
    return null;
  }
}
