import 'package:flutter_bdd_suite/lifecycle_listener.dart';
import 'package:flutter_bdd_suite/models/feature_model.dart';
import 'package:flutter_bdd_suite/models/scenario_model.dart';
import 'package:flutter_bdd_suite/models/step_hook_contexts.dart';

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

  /// An optional tag expression to conditionally execute this hook.
  /// For example: `@browser and not @headless`.
  @override
  String? get tagExpression => null;

  /// Invoked once before the entire test suite begins execution.
  @override
  Future<void> onBeforeAll() async {}

  /// Invoked before the execution of a specific [FeatureInfo].
  @override
  Future<void> onBeforeFeature(FeatureInfo feature) async {}

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

  /// Invoked immediately before a step executes.
  ///
  /// [context.stepText] is the resolved step text (after parameter substitution
  /// for Scenario Outlines).  [context.world] is the shared
  /// [WidgetTesterWorld].  [context.scenario] provides the context of the
  /// currently running scenario, allowing hooks to inspect its name and tags.
  ///
  /// Per the Cucumber specification, this method is **not** called for steps
  /// that are skipped because a prior step in the same scenario did not pass.
  @override
  Future<void> onBeforeStep(BeforeStepContext context) async {}

  /// Invoked immediately after a step completes execution.
  ///
  /// [context.result] carries the outcome (passed, failed, pending, undefined,
  /// or ambiguous) along with timing and step metadata.  [context.scenario]
  /// provides the context of the currently running scenario.
  ///
  /// Per the Cucumber specification, this method is **not** called for steps
  /// that are skipped because a prior step in the same scenario did not pass.
  @override
  Future<void> onAfterStep(AfterStepContext context) async {}
}
