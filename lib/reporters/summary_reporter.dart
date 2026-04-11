import 'package:flutter_bdd_suite/logger.dart';
import 'package:flutter_bdd_suite/models/feature_model.dart';
import 'package:flutter_bdd_suite/models/scenario_model.dart';
import 'package:flutter_bdd_suite/models/step_hook_contexts.dart';
import 'package:flutter_bdd_suite/reporters/integration_reporter.dart';
import 'package:flutter_bdd_suite/steps/step_result.dart';
import 'package:flutter_bdd_suite/utils/enums.dart';
import 'package:flutter_bdd_suite/utils/terminal_colors.dart';

/// A console reporter that prints a one-line scenario summary and overall
/// elapsed time after all scenarios have finished.
///
/// Output format:
/// ```
/// 5 scenarios (3 passed, 1 failed, 1 skipped)
/// 0m12.345s
/// ```
///
/// Register this reporter via [IntegrationTestConfig.reporters]:
/// ```dart
/// reporters: [SummaryReporter()],
/// ```
class SummaryReporter extends IntegrationReporter {
  /// Wall-clock time recorded when [onBeforeAll] fires; used to compute total
  /// elapsed time in [onAfterAll].
  DateTime? _startTime;

  /// Running count of all scenarios encountered during the suite run.
  int _totalScenarios = 0;

  /// Running count of scenarios where every step passed.
  int _passedScenarios = 0;

  /// Running count of scenarios where at least one step failed, was pending,
  /// undefined, or ambiguous.
  int _failedScenarios = 0;

  /// Running count of scenarios where steps were skipped due to a prior step
  /// not passing.
  int _skippedScenarios = 0;

  /// Incremental status for the scenario that is currently executing.
  ///
  /// Initialised to [ScenarioStatus.passed] in [onBeforeScenario] and
  /// downgraded by [onAfterStep] as individual steps complete.
  ScenarioStatus? _currentStatus;

  SummaryReporter();

  @override
  int get priority => 0;

  /// Records the suite start time so that elapsed time can be computed later.
  @override
  Future<void> onBeforeAll() async {
    _startTime = DateTime.now();
  }

  /// Increments the scenario counter and resets [_currentStatus] to
  /// [ScenarioStatus.passed] at the start of each scenario.
  @override
  Future<void> onBeforeScenario(ScenarioInfo scenario) async {
    _totalScenarios++;
    _currentStatus = ScenarioStatus.passed;
  }

  /// Downgrades [_currentStatus] if the step did not pass.
  ///
  /// A failed/pending/undefined/ambiguous step marks the scenario as
  /// [ScenarioStatus.failed].  A skipped step marks it as
  /// [ScenarioStatus.skipped] only if no failure has been recorded yet.
  @override
  Future<void> onAfterStep(AfterStepContext context) async {
    final result = context.result;
    if (result is StepFailure ||
        result is StepPending ||
        result is StepUndefined ||
        result is StepAmbiguous) {
      _currentStatus = ScenarioStatus.failed;
    } else if (result is StepSkipped) {
      if (_currentStatus == ScenarioStatus.passed) {
        _currentStatus = ScenarioStatus.skipped;
      }
    }
  }

  /// Buckets the completed scenario into the appropriate counter based on
  /// [_currentStatus].
  @override
  Future<void> onAfterScenario(ScenarioResult result) async {
    switch (_currentStatus) {
      case ScenarioStatus.passed:
        _passedScenarios++;
      case ScenarioStatus.failed:
        _failedScenarios++;
      case ScenarioStatus.skipped:
        _skippedScenarios++;
      default:
        break;
    }
  }

  /// Prints the scenario summary and total elapsed time to the console.
  @override
  Future<void> onAfterAll() async {
    final elapsed = DateTime.now().difference(_startTime!);
    final mins = elapsed.inMinutes;
    final secs = elapsed.inSeconds % 60;
    final millis = (elapsed.inMilliseconds % 1000).toString().padLeft(3, '0');

    logLine('');
    logLine(
      '$_totalScenarios scenarios '
      '($green$_passedScenarios passed$reset, '
      '$red$_failedScenarios failed$reset, '
      '$yellow$_skippedScenarios skipped$reset)',
    );
    logLine('${mins}m$secs.${millis}s');
    logLine('');
  }

  @override
  Map<String, dynamic> toJson() => {};

  @override
  Future<void> onBeforeStep(BeforeStepContext _) async {}

  @override
  Future<void> onBeforeFeature(FeatureInfo _) async {}

  @override
  Future<void> onAfterFeature(FeatureInfo _) async {}
}
