import 'dart:collection';
import 'package:flutter_bdd_suite/world/test_world.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// A default dynamic implementation of [World].
///
/// It acts as a state container, allowing data to be shared between different steps
/// in the same scenario using the attachments map ([setAttachment] and [getAttachment]).
class WidgetTesterWorld implements World {
  /// Internal state for framework setup. Not exposed to end-user steps directly.
  late final IntegrationTestWidgetsFlutterBinding binding;
  WidgetTester? testerOrNull;

  final Map<String, Object> _attachments = HashMap();
  dynamic multilineArgToInject;

  WidgetTester get tester {
    if (testerOrNull == null) {
      throw StateError(
        'WidgetTester has not been initialized yet. This usually happens when '
        'accessing "tester" inside a hook before the Flutter test runner has started '
        'the execution.',
      );
    }
    return testerOrNull!;
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
