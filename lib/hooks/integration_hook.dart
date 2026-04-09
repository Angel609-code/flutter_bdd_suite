import 'package:flutter_bdd_suite/lifecycle_listener.dart';
import 'package:flutter_bdd_suite/models/feature_model.dart';
import 'package:flutter_bdd_suite/models/scenario_model.dart';
import 'package:flutter_bdd_suite/steps/step_result.dart';
import 'package:flutter_bdd_suite/world/widget_tester_world.dart';

/// A base class for creating hooks that tap into the BDD test lifecycle.
///
/// Hooks allow you to execute custom code at specific points during the test suite execution.
/// By extending [IntegrationHook], you can override only the lifecycle methods you need,
/// such as setting up databases before a scenario, taking screenshots after a step fails,
/// or resetting state between features.
abstract class IntegrationHook implements LifecycleListener {
  /// The execution priority of this hook relative to others.
  /// Hooks with a higher priority value run first.
  @override
  int get priority => 0;

  /// Invoked once before the entire test suite begins execution.
  @override
  Future<void> onBeforeAll() async {}

  /// Invoked before the execution of a specific [FeatureInfo].
  @override
  Future<void> onFeatureStarted(FeatureInfo feature) async {}

  /// Invoked after the execution of a specific [FeatureInfo].
  @override
  Future<void> onAfterFeature(FeatureInfo feature) async {}

  /// Invoked once after the entire test suite completes execution.
  @override
  Future<void> onAfterAll() async {}

  /// Invoked before a given [ScenarioInfo] begins execution.
  @override
  Future<void> onBeforeScenario(ScenarioInfo scenario) async {}

  /// Invoked after a given scenario finishes execution.
  ///
  /// Use [result.status] to branch on [ScenarioExecutionStatus.passed],
  /// [ScenarioExecutionStatus.failed], or [ScenarioExecutionStatus.skipped].
  @override
  Future<void> onAfterScenario(ScenarioResult result) async {}

  /// Invoked immediately before a step executes. Provides the raw [stepText] and the current [world].
  @override
  Future<void> onBeforeStep(String stepText, WidgetTesterWorld world) async {}

  /// Invoked immediately after a step completes execution. Provides the [StepResult] and the current [world].
  @override
  Future<void> onAfterStep(StepResult result, WidgetTesterWorld world) async {}
}
