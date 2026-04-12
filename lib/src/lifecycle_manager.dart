import 'package:flutter_bdd_suite/src/lifecycle_listener.dart';
import 'package:flutter_bdd_suite/src/logger.dart';
import 'package:flutter_bdd_suite/src/models/feature_model.dart';
import 'package:flutter_bdd_suite/src/models/scenario_model.dart';
import 'package:flutter_bdd_suite/src/models/step_hook_contexts.dart';
import 'package:flutter_bdd_suite/src/steps/step_result.dart';
import 'package:flutter_bdd_suite/src/world/widget_tester_world.dart';
import 'package:flutter_bdd_suite/src/utils/expression_evaluator.dart';

/// Dispatches lifecycle events to a prioritised list of [LifecycleListener]s.
///
/// Owns two sorted copies of the listener list:
/// - [_listeners] — descending priority order, used for `Before*` events so
///   that higher-priority listeners run first.
/// - [_reversedListeners] — ascending priority order, used for `After*` events
///   so that higher-priority listeners run last (mirroring Cucumber's hook
///   ordering contract).
///
/// Each dispatch method catches and logs individual listener errors so that one
/// misbehaving hook or reporter never blocks the remaining listeners.
class LifecycleManager {
  /// Listeners sorted by descending [LifecycleListener.priority].
  ///
  /// Used for `Before*` dispatches.
  final List<LifecycleListener> _listeners;

  /// Listeners sorted by ascending [LifecycleListener.priority].
  ///
  /// Used for `After*` dispatches, giving higher-priority listeners the last
  /// word on teardown — consistent with Cucumber's hook ordering contract.
  final List<LifecycleListener> _reversedListeners;

  /// The feature currently being executed; used when evaluating
  /// [LifecycleListener.tagExpression] for conditional hooks.
  FeatureInfo? _currentFeature;

  /// The scenario currently being executed; used when evaluating
  /// [LifecycleListener.tagExpression] for conditional hooks.
  ScenarioInfo? _currentScenario;

  LifecycleManager(List<LifecycleListener> listeners)
    : _listeners = [...listeners]
        ..sort((a, b) => b.priority.compareTo(a.priority)),
      _reversedListeners = [...listeners]
        ..sort((a, b) => a.priority.compareTo(b.priority));

  /// Returns `true` when [listener] should run for the current feature/scenario.
  ///
  /// A listener with a `null` or empty [LifecycleListener.tagExpression] always
  /// matches.  Otherwise the expression is evaluated against the union of
  /// [_currentFeature]'s tags and [_currentScenario]'s tags.
  bool _matchesTags(LifecycleListener listener) {
    if (listener.tagExpression == null ||
        listener.tagExpression!.trim().isEmpty) {
      return true;
    }

    final expression = parseTagExpression(listener.tagExpression!);

    final featureTags = _currentFeature?.tags ?? const <String>[];
    final scenarioTags = _currentScenario?.tags ?? const <String>[];
    final activeTags = {...featureTags, ...scenarioTags}.toSet();

    return expression.evaluate(activeTags);
  }

  /// Notifies all listeners that the suite is about to start.
  ///
  /// Tag expressions are **not** evaluated here because no feature or scenario
  /// is active yet — all listeners are notified unconditionally.
  Future<void> onBeforeAll() async {
    for (final listener in _listeners) {
      try {
        await listener.onBeforeAll();
      } catch (e, st) {
        logLine('Error in onBeforeAll: $e\n$st');
      }
    }
  }

  /// Notifies all listeners that the suite has finished.
  ///
  /// Tag expressions are **not** evaluated here — all listeners are notified
  /// unconditionally.  Listeners are called in reversed (ascending) priority
  /// order so that teardown mirrors setup.
  Future<void> onAfterAll() async {
    for (final listener in _reversedListeners) {
      try {
        await listener.onAfterAll();
      } catch (e, st) {
        logLine('Error in onAfterAll: $e\n$st');
      }
    }
  }

  /// Records [feature] as the active feature and notifies matching listeners.
  Future<void> onBeforeFeature(FeatureInfo feature) async {
    _currentFeature = feature;
    for (final listener in _listeners) {
      if (!_matchesTags(listener)) continue;
      try {
        await listener.onBeforeFeature(feature);
      } catch (e, st) {
        logLine('Error in onBeforeFeature: $e\n$st');
      }
    }
  }

  /// Notifies matching listeners that [feature] has finished, then clears the
  /// active feature state.
  Future<void> onAfterFeature(FeatureInfo feature) async {
    for (final listener in _reversedListeners) {
      if (!_matchesTags(listener)) continue;
      try {
        await listener.onAfterFeature(feature);
      } catch (e, st) {
        logLine('Error in onAfterFeature: $e\n$st');
      }
    }
    _currentFeature = null;
  }

  /// Records [scenario] as the active scenario and notifies matching listeners.
  Future<void> onBeforeScenario(ScenarioInfo scenario) async {
    _currentScenario = scenario;
    for (final listener in _listeners) {
      if (!_matchesTags(listener)) continue;
      try {
        await listener.onBeforeScenario(scenario);
      } catch (e, st) {
        logLine(
          'Error in onBeforeScenario("${scenario.scenarioName}"): $e\n$st',
        );
      }
    }
  }

  /// Notifies matching listeners that [result]'s scenario has finished, then
  /// clears the active scenario state.
  Future<void> onAfterScenario(ScenarioResult result) async {
    for (final listener in _reversedListeners) {
      if (!_matchesTags(listener)) continue;
      try {
        await listener.onAfterScenario(result);
      } catch (e, st) {
        logLine('Error in onAfterScenario("${result.scenarioName}"): $e\n$st');
      }
    }
    _currentScenario = null;
  }

  /// Notifies matching listeners that [stepText] is about to execute.
  ///
  /// Constructs a [BeforeStepContext] from the provided arguments and
  /// [_currentScenario] so that listeners have full scenario context without
  /// tracking it themselves.
  Future<void> onBeforeStep(String stepText, WidgetTesterWorld world) async {
    final context = BeforeStepContext(
      stepText: stepText,
      world: world,
      scenario: _currentScenario,
    );
    for (final listener in _listeners) {
      if (!_matchesTags(listener)) continue;
      try {
        await listener.onBeforeStep(context);
      } catch (e, st) {
        logLine('Error in onBeforeStep("$stepText"): $e\n$st');
      }
    }
  }

  /// Notifies matching listeners that [result]'s step has finished.
  ///
  /// Constructs an [AfterStepContext] from the provided arguments and
  /// [_currentScenario].  Listeners are called in reversed (ascending) priority
  /// order.
  Future<void> onAfterStep(StepResult result, WidgetTesterWorld world) async {
    final context = AfterStepContext(
      result: result,
      world: world,
      scenario: _currentScenario,
    );
    for (final listener in _reversedListeners) {
      if (!_matchesTags(listener)) continue;
      try {
        await listener.onAfterStep(context);
      } catch (e, st) {
        logLine('Error in onAfterStep("${result.stepText}"): $e\n$st');
      }
    }
  }
}
