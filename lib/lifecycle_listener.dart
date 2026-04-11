import 'package:flutter_bdd_suite/models/feature_model.dart';
import 'package:flutter_bdd_suite/models/scenario_model.dart';
import 'package:flutter_bdd_suite/models/step_hook_contexts.dart';

/// Contract implemented by every object that wants to observe the BDD
/// test-execution lifecycle.
///
/// Both [IntegrationHook] (user-authored side-effects) and [IntegrationReporter]
/// (output/reporting) implement this interface.  [LifecycleManager] holds a list
/// of [LifecycleListener]s and fans out each lifecycle event to all registered
/// listeners in priority order.
///
/// All methods have default no-op implementations so that implementors only need
/// to override the events they care about.
abstract class LifecycleListener {
  /// Relative execution order when multiple listeners are registered.
  ///
  /// Listeners with a **higher** value are notified first for `Before*` events
  /// and last for `After*` events (reversed order), mirroring the Cucumber
  /// specification for hook ordering.  Defaults to `0`.
  int get priority => 0;

  /// An optional Gherkin tag expression that gates whether this listener is
  /// invoked for a given feature/scenario.
  ///
  /// When `null` or empty, the listener runs unconditionally.  Otherwise the
  /// expression is evaluated against the union of the active feature tags and
  /// the active scenario tags.
  ///
  /// Example expressions:
  /// - `@smoke` — only scenarios tagged `@smoke`
  /// - `@web and not @headless` — web but not headless scenarios
  /// - `@login or @auth` — either tag
  String? get tagExpression => null;

  /// Invoked once before any scenario in the entire test suite is executed.
  ///
  /// Corresponds to Cucumber's `BeforeAll` global hook.  Use this for one-time
  /// setup such as starting a local server or seeding a shared database.
  Future<void> onBeforeAll() async {}

  /// Invoked once after all scenarios in the entire test suite have finished.
  ///
  /// Corresponds to Cucumber's `AfterAll` global hook.  Use this for global
  /// teardown such as shutting down servers or flushing reports.
  Future<void> onAfterAll() async {}

  /// Invoked before the first scenario inside a feature begins execution.
  ///
  /// [feature] provides the feature name, URI, line number, and tags so that
  /// listeners can scope their behaviour per feature file.
  Future<void> onBeforeFeature(FeatureInfo feature) async {}

  /// Invoked after the last scenario inside a feature has finished execution.
  ///
  /// [feature] is the same [FeatureInfo] that was passed to [onBeforeFeature].
  Future<void> onAfterFeature(FeatureInfo feature) async {}

  /// Invoked before the first step of a scenario executes (including any
  /// Background steps that precede it).
  ///
  /// Corresponds to Cucumber's `Before` scenario hook.  [scenario] exposes the
  /// scenario name, line, tags, and step list.
  ///
  /// > **Tip:** Prefer a Gherkin `Background` section over a [onBeforeScenario]
  /// > hook for any setup that should be visible to readers of the feature file.
  /// > Reserve this hook for low-level concerns such as starting a browser or
  /// > resetting a database.
  Future<void> onBeforeScenario(ScenarioInfo scenario) async {}

  /// Invoked after the last step of a scenario has finished, regardless of
  /// whether any step failed, was pending, undefined, or skipped.
  ///
  /// Corresponds to Cucumber's `After` scenario hook.  [result] carries both
  /// the original [ScenarioInfo] and the final [ScenarioExecutionStatus], so
  /// listeners can react to the outcome — for example, taking a screenshot only
  /// when a scenario fails.
  Future<void> onAfterScenario(ScenarioResult result) async {}

  /// Invoked immediately before a step executes.
  ///
  /// [context] bundles the resolved step text (after parameter substitution for
  /// Scenario Outlines), the shared [WidgetTesterWorld], and the currently
  /// running [ScenarioInfo].  Using a context object keeps the signature stable
  /// — new fields can be added to [BeforeStepContext] in the future without
  /// breaking existing overrides.
  ///
  /// Per the Cucumber specification, this method is **not** called for steps
  /// that are skipped because a prior step in the same scenario did not pass.
  Future<void> onBeforeStep(BeforeStepContext context) async {}

  /// Invoked immediately after a step completes.
  ///
  /// [context] bundles the step outcome ([StepSuccess], [StepFailure],
  /// [StepPending], [StepUndefined], [StepSkipped], or [StepAmbiguous]) along
  /// with step timing and metadata, the shared [WidgetTesterWorld], and the
  /// currently running [ScenarioInfo].  Using a context object keeps the
  /// signature stable — new fields can be added to [AfterStepContext] in the
  /// future without breaking existing overrides.
  ///
  /// Per the Cucumber specification, **user hooks** ([IntegrationHook]) do not
  /// receive this callback for skipped steps.  **Reporters**
  /// ([IntegrationReporter]) do receive it for skipped steps so they can
  /// accurately reflect every step in their output.
  Future<void> onAfterStep(AfterStepContext context) async {}
}
