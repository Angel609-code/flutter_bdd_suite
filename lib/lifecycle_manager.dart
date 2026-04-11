import 'package:flutter_bdd_suite/lifecycle_listener.dart';
import 'package:flutter_bdd_suite/logger.dart';
import 'package:flutter_bdd_suite/models/feature_model.dart';
import 'package:flutter_bdd_suite/models/scenario_model.dart';
import 'package:flutter_bdd_suite/steps/step_result.dart';
import 'package:flutter_bdd_suite/world/widget_tester_world.dart';
import 'package:flutter_bdd_suite/utils/expression_evaluator.dart';

class LifecycleManager {
  final List<LifecycleListener> _listeners;
  final List<LifecycleListener> _reversedListeners;

  FeatureInfo? _currentFeature;
  ScenarioInfo? _currentScenario;

  LifecycleManager(List<LifecycleListener> listeners)
    : _listeners = [...listeners]
        ..sort((a, b) => b.priority.compareTo(a.priority)),
      _reversedListeners = [...listeners]
        ..sort((a, b) => a.priority.compareTo(b.priority));

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

  Future<void> onBeforeAll() async {
    for (final listener in _listeners) {
      try {
        await listener.onBeforeAll();
      } catch (e, st) {
        logLine('Error in onBeforeAll: $e\n$st');
      }
    }
  }

  Future<void> onAfterAll() async {
    for (final listener in _reversedListeners) {
      try {
        await listener.onAfterAll();
      } catch (e, st) {
        logLine('Error in onAfterAll: $e\n$st');
      }
    }
  }

  Future<void> onFeatureStarted(FeatureInfo feature) async {
    _currentFeature = feature;
    for (final listener in _listeners) {
      if (!_matchesTags(listener)) continue;
      try {
        await listener.onFeatureStarted(feature);
      } catch (e, st) {
        logLine('Error in onFeatureStarted: $e\n$st');
      }
    }
  }

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

  Future<void> onBeforeStep(String stepText, WidgetTesterWorld world) async {
    for (final listener in _listeners) {
      if (!_matchesTags(listener)) continue;
      try {
        await listener.onBeforeStep(stepText, world);
      } catch (e, st) {
        logLine('Error in onBeforeStep("$stepText"): $e\n$st');
      }
    }
  }

  Future<void> onAfterStep(StepResult result, WidgetTesterWorld world) async {
    for (final listener in _reversedListeners) {
      if (!_matchesTags(listener)) continue;
      try {
        await listener.onAfterStep(result, world);
      } catch (e, st) {
        logLine('Error in onAfterStep("${result.stepText}"): $e\n$st');
      }
    }
  }
}
