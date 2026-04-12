import 'package:flutter_bdd_suite/src/lifecycle_listener.dart';

/// A base class for creating hooks that tap into the BDD test lifecycle.
///
/// Hooks allow you to execute custom code at specific points during the test suite execution.
/// By extending [IntegrationHook], you can override only the lifecycle methods you need,
/// such as setting up databases before a scenario, taking screenshots after a step fails,
/// or resetting state between features.
abstract class IntegrationHook extends LifecycleListener {
  /// The execution priority of this hook relative to others.
  /// Hooks with a higher priority value run first.

  /// An optional tag expression to conditionally execute this hook.
  /// For example: `@browser and not @headless`.

  /// Invoked once before the entire test suite begins execution.

  /// Invoked before the execution of a specific [FeatureInfo].

  /// Invoked after the execution of a specific [FeatureInfo].

  /// Invoked once after the entire test suite completes execution.

  /// Invoked before a given [ScenarioInfo] begins execution.

  /// Invoked after a given scenario finishes execution.
  ///
  /// Use [result.status] to branch on [ScenarioExecutionStatus.passed],
  /// [ScenarioExecutionStatus.failed], or [ScenarioExecutionStatus.skipped].

  /// Invoked immediately before a step executes.
  ///
  /// [context.stepText] is the resolved step text (after parameter substitution
  /// for Scenario Outlines).  [context.world] is the shared
  /// [WidgetTesterWorld].  [context.scenario] provides the context of the
  /// currently running scenario, allowing hooks to inspect its name and tags.
  ///
  /// Per the Cucumber specification, this method is **not** called for steps
  /// that are skipped because a prior step in the same scenario did not pass.

  /// Invoked immediately after a step completes execution.
  ///
  /// [context.result] carries the outcome (passed, failed, pending, undefined,
  /// or ambiguous) along with timing and step metadata.  [context.scenario]
  /// provides the context of the currently running scenario.
  ///
  /// Per the Cucumber specification, this method is **not** called for steps
  /// that are skipped because a prior step in the same scenario did not pass.
}
