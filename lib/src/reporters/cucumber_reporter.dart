import 'package:flutter_bdd_suite/src/logger.dart';
import 'package:flutter_bdd_suite/src/models/feature_model.dart';
import 'package:flutter_bdd_suite/src/models/scenario_model.dart';
import 'package:flutter_bdd_suite/src/models/step_hook_contexts.dart';
import 'package:flutter_bdd_suite/src/reporters/cucumber_formatter.dart';
import 'package:flutter_bdd_suite/src/reporters/integration_reporter.dart';
import 'package:flutter_bdd_suite/src/steps/step_result.dart';
import 'package:flutter_bdd_suite/src/utils/enums.dart';

/// A reporter that collects test execution data and emits it using a formatter.
///
/// This reporter tracks features, scenarios, and steps during integration
/// test execution and prints a formatted summary at the end.
class CucumberReporter extends IntegrationReporter {
  /// Creates a new [CucumberReporter] with the given [formatter] and [logger].
  CucumberReporter({required this.formatter, required this.logger});

  /// The formatter used to style the output.
  final CucumberFormatter formatter;

  /// The logger used to write the formatted output.
  final BddLogger logger;

  DateTime? _startTime;

  int _totalFeatures = 0;
  int _totalScenarios = 0;
  int _passedScenarios = 0;
  int _failedScenarios = 0;
  int _skippedScenarios = 0;

  int _totalSteps = 0;
  int _passedSteps = 0;
  int _failedSteps = 0;
  int _skippedSteps = 0;

  ScenarioStatus? _currentScenarioStatus;
  FeatureInfo? _currentFeature;

  @override
  int get priority => -100; // Run after most other reporters

  @override
  Future<void> onBeforeAll() async {
    _startTime = DateTime.now();
  }

  @override
  Future<void> onBeforeFeature(FeatureInfo feature) async {
    _currentFeature = feature;
    _totalFeatures++;
    logger.write(formatter.formatFeature(feature.featureName));
  }

  @override
  Future<void> onBeforeScenario(ScenarioInfo scenario) async {
    _totalScenarios++;
    _currentScenarioStatus = ScenarioStatus.passed;
    logger.write(formatter.formatScenario(scenario.scenarioName));
  }

  @override
  Future<void> onAfterStep(AfterStepContext context) async {
    final result = context.result;
    _totalSteps++;

    switch (result.status) {
      case StepStatus.success:
        _passedSteps++;
      case StepStatus.failure:
      case StepStatus.ambiguous:
        _failedSteps++;
        _currentScenarioStatus = ScenarioStatus.failed;
      case StepStatus.skipped:
        _skippedSteps++;
        if (_currentScenarioStatus == ScenarioStatus.passed) {
          _currentScenarioStatus = ScenarioStatus.skipped;
        }
      case StepStatus.undefined:
      case StepStatus.pending:
        _failedSteps++; // These block following steps, treated as failure
        _currentScenarioStatus = ScenarioStatus.failed;
    }

    logger.write(formatter.formatStep(result, uri: _currentFeature?.uri));

    final errorMsg = formatter.formatError(result);
    if (errorMsg != null) {
      logger.write(errorMsg);
    }

    if (result is StepFailure && result.stackTrace != null) {
      final stLines = formatter.formatStackTrace(result.stackTrace!);
      for (final line in stLines) {
        logger.write(line);
      }
    }
  }

  @override
  Future<void> onAfterScenario(ScenarioResult result) async {
    switch (_currentScenarioStatus) {
      case ScenarioStatus.passed:
        _passedScenarios++;
      case ScenarioStatus.failed:
        _failedScenarios++;
      case ScenarioStatus.skipped:
        _skippedScenarios++;
      case _:
        break;
    }
    logger.write(''); // Extra newline between scenarios
  }

  @override
  Future<void> onAfterAll() async {
    final elapsed = DateTime.now().difference(_startTime!);

    logger.write(formatter.formatSummaryHeader());

    // Feature summary
    logger.write(formatter.formatCount(_totalFeatures, 'feature'));

    // Scenario summary
    final scenarioDetails = formatter.formatDetails(
      passed: _passedScenarios,
      failed: _failedScenarios,
      skipped: _skippedScenarios,
    );
    logger.write(
      formatter.formatCount(
        _totalScenarios,
        'scenario',
        details: scenarioDetails.isNotEmpty ? scenarioDetails : null,
      ),
    );

    // Step summary
    final stepDetails = formatter.formatDetails(
      passed: _passedSteps,
      failed: _failedSteps,
      skipped: _skippedSteps,
    );
    logger.write(
      formatter.formatCount(
        _totalSteps,
        'step',
        details: stepDetails.isNotEmpty ? stepDetails : null,
      ),
    );

    logger.write(formatter.formatDuration(elapsed));
    logger.write('');
  }

  @override
  Map<String, dynamic> toJson() => {};
}
