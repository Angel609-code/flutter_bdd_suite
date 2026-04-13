import 'dart:convert' show jsonDecode;
import 'package:flutter_bdd_suite/src/integration_test_config.dart';
import 'package:flutter_bdd_suite/src/lifecycle_manager.dart';
import 'package:flutter_bdd_suite/src/logger.dart';
import 'package:flutter_bdd_suite/src/models/models.dart';
import 'package:flutter_bdd_suite/src/server/integration_test_server.dart';
import 'package:flutter_bdd_suite/src/steps/step_exceptions.dart';
import 'package:flutter_bdd_suite/src/steps/step_result.dart';
import 'package:flutter_bdd_suite/src/steps/steps_registry.dart';
import 'package:flutter_bdd_suite/src/bootstrap.dart';
import 'package:flutter_bdd_suite/src/utils/step_definition_generic.dart';
import 'package:flutter_bdd_suite/src/reporters/cucumber_formatter.dart';
import 'package:flutter_bdd_suite/src/reporters/cucumber_reporter.dart';
import 'package:flutter_bdd_suite/src/models/report_presentation.dart';
import 'package:flutter_bdd_suite/src/utils/terminal_colors.dart';
import 'package:flutter_bdd_suite/src/world/widget_tester_world.dart';

import 'package:flutter_test/flutter_test.dart';

class IntegrationTestHelper {
  final IntegrationTestConfig config;
  late final ReportPresentation _presentation;
  List<Step> _backgroundSteps = [];
  List<Step> get backgroundSteps => _backgroundSteps;

  late final LifecycleManager _hookManager;
  late final LifecycleManager _reporterManager;
  late final WidgetTesterWorld _world;

  /// Per-instance registry built from [IntegrationTestConfig.steps].
  ///
  /// Created once in the factory and never mutated, ensuring full isolation
  /// between concurrent or sequential test suites.
  late final StepsRegistry _stepsRegistry;

  /// Guards [registerSuiteHooks] so that `setUpAll`/`tearDownAll` are
  /// registered at most once per instance, even if [registerSuiteHooks] is
  /// called more than once.
  bool _suiteHooksRegistered = false;

  bool _skipRemaining = false;
  bool _errorOnBackground = false;
  bool _executedError = false;
  String _scenarioName = '';
  Object? _firstError;
  StackTrace? _firstStackTrace;
  ScenarioExecutionStatus _scenarioStatus = ScenarioExecutionStatus.passed;

  // ── Suite-level lifecycle ───────────────────────────────────────────────────

  /// Register `setUpAll` / `tearDownAll` callbacks for the global hook and
  /// reporter lifecycle.
  ///
  /// Call this **exactly once** at the suite level, before any `group` or
  /// `testWidgets` call — typically from the entry-point that orchestrates
  /// all feature runners.
  ///
  /// Subsequent calls on the same instance are silently ignored (idempotent),
  /// so it is safe to call from multiple code paths.
  ///
  /// ```dart
  /// // all_integration_tests.dart (master runner)
  /// void main() async {
  ///   final helper = await IntegrationTestHelper.create(config: config);
  ///   helper.registerSuiteHooks(); // ← call once here
  ///
  ///   login.main();
  ///   dashboard.main();
  /// }
  /// ```
  void registerSuiteHooks() {
    if (_suiteHooksRegistered) return;

    setUpAll(() async {
      await _hookManager.onBeforeAll();
      await _reporterManager.onBeforeAll();
    });

    tearDownAll(() async {
      await _hookManager.onAfterAll();
      await _reporterManager.onAfterAll();
    });

    _suiteHooksRegistered = true;
  }

  /// Documented counterpart to [registerSuiteHooks] for explicit lifecycle
  /// bookending.
  ///
  /// Currently a no-op — Flutter's test framework owns `tearDownAll`
  /// scheduling once it has been registered via [registerSuiteHooks].
  /// Reserved for future use (e.g. force-flushing async reporters).
  void disposeSuiteHooks() {
    // Intentionally empty.
    // Teardown is handled by the tearDownAll callback registered in
    // registerSuiteHooks(). This method exists as an explicit API bookend
    // for callers that want symmetric open/close semantics.
  }

  // ── Factory ─────────────────────────────────────────────────────────────────

  static Future<IntegrationTestHelper> create({
    required IntegrationTestConfig config,
    List<String> backgroundSteps = const [],
    IntegrationTestServer? server,
  }) async {
    await bootstrap(config);
    final helper = IntegrationTestHelper._(config);
    helper._backgroundSteps = helper._parseStepsFromJsonList(backgroundSteps);

    return helper;
  }

  IntegrationTestHelper._(this.config) {
    _hookManager = LifecycleManager(config.hooks);

    // Allow CLI flags (via --dart-define) to override config values
    final envNoColors = const String.fromEnvironment('FGP_NO_COLORS');
    final envShowPaths = const String.fromEnvironment('FGP_SHOW_PATHS');
    final envShowStackTraces = const String.fromEnvironment(
      'FGP_SHOW_STACK_TRACES',
    );

    _presentation = config.presentation.copyWith(
      useColors: envNoColors.isNotEmpty ? envNoColors != 'true' : null,
      showStepPaths: envShowPaths.isNotEmpty ? envShowPaths == 'true' : null,
      showStackTraces:
          envShowStackTraces.isNotEmpty ? envShowStackTraces == 'true' : null,
    );

    final reporters = [...config.reporters];
    if (config.useDefaultReporter &&
        !reporters.any((r) => r is CucumberReporter)) {
      reporters.insert(
        0,
        CucumberReporter(
          formatter: CucumberFormatter(_presentation),
          logger: bddLogger,
        ),
      );
    }
    _reporterManager = LifecycleManager(reporters);

    _world = WidgetTesterWorld();
    _world.binding = binding;

    // Build a per-execution registry from the built-in defaults plus any
    // custom steps declared in the config. No static mutation occurs.
    _stepsRegistry = StepsRegistry(extraSteps: config.steps);
  }

  // ── Public accessors ────────────────────────────────────────────────────────

  LifecycleManager get hookManager => _hookManager;

  LifecycleManager get reporterManager => _reporterManager;

  WidgetTesterWorld get world => _world;

  // ── Feature / scenario lifecycle ────────────────────────────────────────────

  Future<void> setUpFeature({
    required FeatureInfo featureInfo,
    List<String>? backgroundSteps,
  }) async {
    if (backgroundSteps != null) {
      _backgroundSteps = _parseStepsFromJsonList(backgroundSteps);
    } else {
      _backgroundSteps = [];
    }

    // Reset feature-level state for orchestrated runs where the helper is shared.
    _skipRemaining = false;
    _errorOnBackground = false;
    _scenarioName = '';
    _firstError = null;
    _firstStackTrace = null;
    _scenarioStatus = ScenarioExecutionStatus.passed;
    _executedError = false;

    await _hookManager.onBeforeFeature(featureInfo);
    await _reporterManager.onBeforeFeature(featureInfo);
  }

  Future<void> setUp(WidgetTester tester, ScenarioInfo scenario) async {
    // Reset all per-scenario execution state at the start of every scenario.
    //
    // The same fields are also reset in [setUpFeature] for orchestrated multi-
    // feature runs, but that reset happens only once per feature group (via
    // setUpAll).  This per-scenario reset ensures that each testWidgets call
    // starts with a clean slate — regardless of how many scenarios have already
    // run in the same feature.
    _skipRemaining = false;
    _errorOnBackground = false;
    _scenarioStatus = ScenarioExecutionStatus.passed;
    _executedError = false;
    _firstError = null;
    _firstStackTrace = null;
    _scenarioName = '';

    _world.testerOrNull = tester;

    // If an explicit setUp is provided, call it.
    if (config.setUp != null) {
      await config.setUp!.call(_world.tester);
    } else {
      // Safety guard: if no custom setUp is provided, the app MUST be mounted
      // before execution proceeds. This prevents generic 'No widget' failures.
      if (tester.allElements.isEmpty) {
        throw StateError(
          'No widget is mounted in the widget tree. You must either provide a '
          '"setUp" callback in your "IntegrationTestConfig" that calls '
          '"tester.pumpWidget(...)", or include a step in your feature file '
          'that launches the application (e.g. "Given the app is launched").',
        );
      }
    }

    await _hookManager.onBeforeScenario(scenario);
    await _reporterManager.onBeforeScenario(scenario);

    if (backgroundSteps.isNotEmpty) {
      for (final step in backgroundSteps) {
        await _executeStep(step, true, scenario: scenario);
      }
    }
  }

  Future<void> runStepsForScenario(ScenarioInfo scenario) async {
    final steps = _parseStepsFromJsonList(scenario.steps);

    for (final step in steps) {
      await _executeStep(step, false, scenario: scenario);
    }

    try {
      if (_executedError == false && _firstError != null) {
        _executedError = true;
        if (_firstStackTrace != null) {
          throw Error.throwWithStackTrace(_firstError!, _firstStackTrace!);
        } else {
          throw _firstError!;
        }
      }
    } catch (e, st) {
      await _handleTestError(e, st);
    } finally {
      final scenarioResult = ScenarioResult(
        scenario: scenario,
        status: _scenarioStatus,
      );

      await _hookManager.onAfterScenario(scenarioResult);
      await _reporterManager.onAfterScenario(scenarioResult);
    }
  }

  Future<void> testScenario(WidgetTester tester, ScenarioInfo scenario) async {
    await setUp(tester, scenario);
    await runStepsForScenario(scenario);
  }

  // ── Step execution ──────────────────────────────────────────────────────────

  /// Constructs the [StepMultilineArg] from the step's first-class fields.
  ///
  /// Returns a [StepTable] if the step has a data table, a [StepDocString] if
  /// it has a doc-string, or `null` if it has neither. The Gherkin spec
  /// guarantees that both can never be set simultaneously.
  StepMultilineArg? _buildMultilineArg(Step step) {
    if (step.table != null) return StepTable(step.table!);
    if (step.docString != null) return StepDocString(step.docString!);
    return null;
  }

  Future<void> _executeStep(
    Step step,
    bool isBackground, {
    ScenarioInfo? scenario,
  }) async {
    final start = DateTime.now().microsecondsSinceEpoch;
    late StepResult result;

    // Per Cucumber specification: if a prior step did not pass, the following
    // step and its hooks are skipped. Reporters still receive onAfterStep for
    // skipped steps so they can accurately reflect every step in their output.
    if (_skipRemaining) {
      final duration = DateTime.now().microsecondsSinceEpoch - start;
      result = StepResult.skipped(
        step.text,
        step.line,
        duration,
        table: step.table,
        docString: step.docString,
      );

      if (!isBackground) _scenarioStatus = ScenarioExecutionStatus.skipped;

      // Only reporters receive the skipped-step notification; user hooks are
      // intentionally omitted in line with the Cucumber invoke-around contract.
      await _reporterManager.onAfterStep(result, _world);
      return;
    }

    // Step is being executed: fire BeforeStep on both hooks and reporters.
    await _hookManager.onBeforeStep(step.text, _world);
    await _reporterManager.onBeforeStep(step.text, _world);

    // Resolve the step function from the per-execution registry. The
    // multiline argument (table or doc-string) is constructed once from the
    // step's first-class fields and forwarded as a single typed value.
    StepFunction? stepFunction;
    try {
      stepFunction = _stepsRegistry.getStep(step.text);
    } on AmbiguousStepException catch (e) {
      final duration = DateTime.now().microsecondsSinceEpoch - start;
      result = StepAmbiguous(
        step.text,
        step.line,
        duration,
        error: e,
        table: step.table,
        docString: step.docString,
      );
      await _handleStepFailureOrPending(result, step, isBackground, scenario);
      return;
    }

    final multilineArg = _buildMultilineArg(step);
    _world.multilineArgToInject = multilineArg;

    if (stepFunction != null) {
      try {
        // Inject the multiline argument into the world context before execution.
        await stepFunction(_world);

        final duration = DateTime.now().microsecondsSinceEpoch - start;
        result = StepResult.success(
          step.text,
          step.line,
          duration,
          table: step.table,
          docString: step.docString,
        );
      } on PendingStepException {
        final duration = DateTime.now().microsecondsSinceEpoch - start;
        result = StepResult.pending(
          step.text,
          step.line,
          duration,
          table: step.table,
          docString: step.docString,
        );
      } catch (e, st) {
        final duration = DateTime.now().microsecondsSinceEpoch - start;
        result = StepFailure(
          step.text,
          step.line,
          duration,
          error: e,
          stackTrace: st,
          table: step.table,
          docString: step.docString,
        );
      }
    } else {
      final duration = DateTime.now().microsecondsSinceEpoch - start;
      result = StepResult.undefined(
        step.text,
        step.line,
        duration,
        table: step.table,
        docString: step.docString,
      );
    }

    await _handleStepFailureOrPending(result, step, isBackground, scenario);
  }

  Future<void> _handleStepFailureOrPending(
    StepResult result,
    Step step,
    bool isBackground,
    ScenarioInfo? scenario,
  ) async {
    await _hookManager.onAfterStep(result, _world);
    await _reporterManager.onAfterStep(result, _world);

    if (result.status.blocksFollowingSteps) {
      _skipRemaining = true;
      _errorOnBackground = isBackground;
      _scenarioStatus = ScenarioExecutionStatus.failed;

      if (!_errorOnBackground) {
        _scenarioName = scenario!.scenarioName;
      }

      switch (result) {
        case StepFailure():
          if (result.stackTrace != null) {
            _firstError = result.error;
            _firstStackTrace = result.stackTrace!;
          } else {
            _firstError = result.error;
          }
        case StepAmbiguous():
          _firstError = result.error;
        default:
          if (result.status == StepStatus.undefined) {
            _firstError = 'Step undefined: ${step.text}';
          } else if (result.status == StepStatus.pending) {
            _firstError = 'Step pending: ${step.text}';
          }
      }
    }
  }

  // ── Error Handling ─────────────────────────────────────────────────────────

  Future<void> _handleTestError(Object error, StackTrace stackTrace) async {
    final r = _presentation.useColors ? red : '';
    final res = _presentation.useColors ? reset : '';

    final cleanError =
        error
            .toString()
            .replaceFirst(RegExp(r'^(Exception|TestFailure):\s*'), '')
            .trim();

    final String errorMessage =
        '${r}Error on step, skipping remaining steps for '
        '${_errorOnBackground ? 'background' : 'scenario: "$_scenarioName"'}:\n$cleanError$res';

    fail(errorMessage);
  }

  List<Step> _parseStepsFromJsonList(List<String> jsonList) {
    return jsonList.map((str) {
      final dynamic decoded = jsonDecode(str);
      if (decoded is! Map<String, dynamic>) {
        throw FormatException('Expected JSON object for step, got: $decoded');
      }
      return Step.fromJson(decoded);
    }).toList();
  }
}
