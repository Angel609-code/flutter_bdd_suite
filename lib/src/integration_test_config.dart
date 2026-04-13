import 'package:flutter_bdd_suite/src/hooks/integration_hook.dart';
import 'package:flutter_bdd_suite/src/reporters/integration_reporter.dart';
import 'package:flutter_bdd_suite/src/utils/step_definition_generic.dart';
import 'package:flutter_bdd_suite/src/models/report_presentation.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// A callback that always exposes its single argument as `binding`.
typedef PreBindingSetup =
    Future<void> Function(IntegrationTestWidgetsFlutterBinding binding);

/// Defines the configuration used by the generated test runner.
///
/// You must provide this config from your `test_config.dart` file.
///
/// This is the main entry point for customizing integration tests.
class IntegrationTestConfig {
  /// Called immediately after `IntegrationTestWidgetsFlutterBinding.ensureInitialized()`.
  /// The IDE will suggest the parameter name “binding” when you write the lambda.
  final PreBindingSetup? onBindingInitialized;

  /// Optional per-scenario setup callback.
  ///
  /// This callback is executed once for each scenario, before Background and
  /// Scenario steps are run.
  ///
  /// Use this when you want to prepare test state at the framework level. Two
  /// common patterns are supported:
  ///
  /// 1) Config-Driven Startup
  /// - Reset state (for example, clear a DI container like GetIt, reset
  ///   in-memory repositories, or wipe local caches).
  /// - Mount the UI by calling `tester.pumpWidget(...)` and then
  ///   `tester.pumpAndSettle()`.
  ///
  /// 2) Custom Step-Driven Startup
  /// - Leave [setUp] as `null` (or use it only for non-UI resets).
  /// - Mount the app inside explicit Gherkin steps, such as a custom Given
  ///   step matching `Given the app is launched`.
  ///
  /// Choosing between these is a style decision:
  /// - Prefer Config-Driven Startup for a strict, always-on baseline.
  /// - Prefer Step-Driven Startup when feature files should control exactly
  ///   when the UI is mounted.
  final Future<void> Function(WidgetTester tester)? setUp;

  /// List of hooks that will be called during the test lifecycle.
  ///
  /// You can implement hooks for:
  /// - Seeding data
  /// - Cleaning up storage
  /// - Setting custom variables
  ///
  /// Hooks are composable and executed in order of descending [priority].
  final List<IntegrationHook> hooks;

  /// List of reporters that receive lifecycle events and produce output
  /// (e.g. [SummaryReporter], [JsonReporter]).
  ///
  /// Reporters are sorted by descending [IntegrationReporter.priority] and
  /// notified at every lifecycle point alongside hooks.
  final List<IntegrationReporter> reporters;

  /// Optional list of additional step definitions to register on top of the
  /// built-in defaults supplied by [StepsRegistry].
  ///
  /// Each entry is created with one of the `genericN` factory functions.
  /// Steps provided here are appended to the registry in the order given.
  final List<StepDefinitionGeneric> steps;

  /// Controls the visual representation and behavior of the reporting output.
  final ReportPresentation presentation;

  /// Whether to automatically register the default [CucumberReporter].
  ///
  /// Defaults to `true`.  Set to `false` if you want to provide your own
  /// reporting logic exclusively.
  final bool useDefaultReporter;

  IntegrationTestConfig({
    this.setUp,
    this.onBindingInitialized,
    this.hooks = const [],
    this.reporters = const [],
    this.steps = const [],
    this.presentation = const ReportPresentation(),
    this.useDefaultReporter = true,
  });
}
