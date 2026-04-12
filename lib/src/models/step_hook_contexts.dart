import 'package:flutter_bdd_suite/src/models/scenario_model.dart';
import 'package:flutter_bdd_suite/src/steps/step_result.dart';
import 'package:flutter_bdd_suite/src/world/widget_tester_world.dart';

/// Carries all contextual information available immediately **before** a step
/// executes.
///
/// Passed to [LifecycleListener.onBeforeStep] (and its overrides in
/// [IntegrationHook] / [IntegrationReporter]) so that the signature stays
/// stable as new fields are added in the future.
class BeforeStepContext {
  /// The resolved step text after any Scenario Outline parameter substitution.
  final String stepText;

  /// The shared [WidgetTesterWorld] for the currently executing scenario.
  final WidgetTesterWorld world;

  /// Contextual information about the currently running scenario, including its
  /// name, line, tags, and step list.  `null` only during background steps that
  /// execute before the first scenario has been recorded.
  final ScenarioInfo? scenario;

  const BeforeStepContext({
    required this.stepText,
    required this.world,
    required this.scenario,
  });
}

/// Carries all contextual information available immediately **after** a step
/// completes.
///
/// Passed to [LifecycleListener.onAfterStep] (and its overrides in
/// [IntegrationHook] / [IntegrationReporter]) so that the signature stays
/// stable as new fields are added in the future.
class AfterStepContext {
  /// The outcome of the step.
  ///
  /// See [StepResult.status] for the [StepStatus] value and, when relevant,
  /// [StepFailure] / [StepAmbiguous] for specialized error details.
  ///
  /// Also carries step timing, text, line number, table, and doc-string.
  final StepResult result;

  /// The shared [WidgetTesterWorld] for the currently executing scenario.
  final WidgetTesterWorld world;

  /// Contextual information about the currently running scenario.  `null` only
  /// during background steps.
  final ScenarioInfo? scenario;

  const AfterStepContext({
    required this.result,
    required this.world,
    required this.scenario,
  });
}
