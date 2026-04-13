import 'dart:convert';
import 'package:flutter_bdd_suite/src/logger.dart';
import 'package:flutter_bdd_suite/src/models/feature_model.dart';
import 'package:flutter_bdd_suite/src/models/json_step_model.dart';
import 'package:flutter_bdd_suite/src/models/report_model.dart';
import 'package:flutter_bdd_suite/src/models/scenario_model.dart';
import 'package:flutter_bdd_suite/src/models/step_hook_contexts.dart';
import 'package:flutter_bdd_suite/src/reporters/integration_reporter.dart';
import 'package:flutter_bdd_suite/src/server/integration_endpoints.dart';
import 'package:flutter_bdd_suite/src/steps/step_result.dart';

// ── Private constants ────────────────────────────────────────────────────────

/// Cucumber JSON report status strings used by [JsonReporter].
///
/// These values must match the strings expected by downstream tooling such as
/// [cucumber-html-reporter](https://www.npmjs.com/package/cucumber-html-reporter).
abstract final class _StepStatus {
  static const passed = 'passed';
  static const skipped = 'skipped';
  static const undefined = 'undefined';
  static const pending = 'pending';
  static const ambiguous = 'ambiguous';
  static const failed = 'failed';
}

const _maxLogMessageLength = 300;

// ── Reporter ─────────────────────────────────────────────────────────────────

/// Creates a Cucumber-compatible JSON report file with the results of the test run.
///
/// This JSON file can be used by the [cucumber-html-reporter](https://www.npmjs.com/package/cucumber-html-reporter)
/// npm package to create a comprehensive HTML report.
///
/// This reporter was inspired by the reporting implementation in the `flutter_gherkin` package,
/// but has been specifically adapted for `integration_test` to replace the older `flutter_driver` approach.
class JsonReporter extends IntegrationReporter {
  /// Accumulated list of all features observed during the test run.
  final List<JsonFeature> _features = [];

  /// JSON model for the scenario that is currently executing.
  JsonScenario? _currentScenario;

  /// JSON model for the feature that is currently executing.
  JsonFeature? _currentFeature;

  /// Buffer for background steps captured before the current scenario starts.
  ///
  /// Collected in [onAfterStep] when [_inBackground] is true, and prepended to
  /// the scenario in [onBeforeScenario].
  final List<JsonStep> _backgroundStepsBuffer = [];
  
  /// Whether the feature-level background element has already been recorded
  /// for the current feature.
  bool _featureBackgroundRecorded = false;

  /// The single, top-level background element emitted once per feature to 
  /// populate the report's feature summary.
  JsonScenario? _featureBackground;

  /// Whether the reporter is currently recording steps for the Background
  /// section (`true`) or for an active Scenario (`false`).
  ///
  /// Set to `true` when a feature begins (or after a scenario ends) so that
  /// the next batch of steps is attributed to the background element.  Set to
  /// `false` when [onBeforeScenario] fires.
  ///
  /// Initialised to `false` as a safe default.  This value is never read
  /// before the first [onBeforeFeature] call (which sets it to `true`),
  /// because [onAfterStep] can only be invoked while a feature is executing.
  bool _inBackground = false;

  JsonReporter({required super.path});

  /// Initialises state for the new feature and prepares the background slot.
  ///
  /// Note: tags are mapped to the line immediately preceding the feature
  /// keyword (`feature.line - 1`) because the Gherkin parser records the
  /// feature's own line, but tags always appear on the line above in the
  /// Cucumber JSON schema.

  @override
  Future<void> onBeforeFeature(FeatureInfo feature) async {
    _currentFeature = JsonFeature(
      uri: feature.uri,
      id: feature.featureName.toLowerCase().replaceAll(' ', '-'),
      name: feature.featureName,
      line: feature.line,
      tags: feature.tags.map((t) => JsonTag(t, feature.line - 1)).toList(),
    );

    _features.add(_currentFeature!);

    _inBackground = true;
    _backgroundStepsBuffer.clear();
    _featureBackgroundRecorded = false;
    _featureBackground = null;
  }

  /// Creates a new [JsonScenario] entry for the scenario that is about to run
  /// and switches the reporter out of background-recording mode.
  ///
  /// Note: tags are mapped to `scenario.line - 1` for the same reason as in
  /// [onBeforeFeature] — tags precede the scenario keyword in the feature file.
  @override
  Future<void> onBeforeScenario(ScenarioInfo scenario) async {
    _inBackground = false;

    final featureId = _currentFeature?.id ?? 'unknown-feature';
    final scenarioId =
        '$featureId;${scenario.scenarioName.toLowerCase().replaceAll(' ', '-')}';

    _currentScenario = JsonScenario(
      keyword: 'Scenario',
      type: 'scenario',
      id: scenarioId,
      name: scenario.scenarioName,
      line: scenario.line,
      tags: scenario.tags.map((t) => JsonTag(t, scenario.line - 1)).toList(),
      steps: List<JsonStep>.from(_backgroundStepsBuffer),
    );
    _currentFeature!.elements.add(_currentScenario!);
  }

  /// Resets the background slot so that the next feature's background steps
  /// are captured in a fresh element.
  @override
  Future<void> onAfterScenario(ScenarioResult result) async {
    _inBackground = true;
    _backgroundStepsBuffer.clear();
    _featureBackgroundRecorded = true;
    _currentScenario = null;
  }

  /// Converts a [StepResult] into a [JsonStep] and appends it to either the
  /// current scenario or the synthetic background element.
  ///
  /// If this is the first background step for the current feature, the
  /// [_BackgroundElement] is created lazily and added to the feature's element
  /// list before the step is appended.
  @override
  Future<void> onAfterStep(AfterStepContext context) async {
    final result = context.result;

    final stepText = result.stepText;
    final line = result.line;
    final parts = stepText.split(' ');
    final keyword = '${parts.first} ';
    final name = parts.skip(1).join(' ');
    late final String status;
    String? errorMessage;

    switch (result.status) {
      case StepStatus.success:
        status = _StepStatus.passed;
      case StepStatus.skipped:
        status = _StepStatus.skipped;
      case StepStatus.undefined:
        status = _StepStatus.undefined;
      case StepStatus.pending:
        status = _StepStatus.pending;
      case StepStatus.ambiguous:
        status = _StepStatus.ambiguous;
        if (result is StepAmbiguous) {
          errorMessage = '${result.error}';
        }
      case StepStatus.failure:
        status = _StepStatus.failed;
        if (result is StepFailure) {
          errorMessage = '${result.error}';
        }
    }

    final jsonStep = JsonStep(
      keyword: keyword,
      name: name,
      line: line,
      status: status,
      errorMessage: errorMessage,
      duration: result.duration,
      table: result.table,
    );

    if (_inBackground) {
      _backgroundStepsBuffer.add(jsonStep);
      
      if (!_featureBackgroundRecorded) {
        if (_featureBackground == null) {
          final featureId = _currentFeature?.id ?? 'unknown-feature';
          _featureBackground = JsonScenario(
            keyword: 'Background',
            type: 'background',
            name: '',
            id: '$featureId;background',
            line: line - 1,
          );
          _currentFeature!.elements.add(_featureBackground!);
        }
        _featureBackground!.steps.add(jsonStep);
      }
    } else {
      _currentScenario?.steps.add(jsonStep);
    }
  }

  /// Serialises all accumulated features to JSON and persists the report via
  /// the bridge server.
  @override
  Future<void> onAfterAll() async {
    final jsonString = jsonEncode(_features.map((f) => f.toJson()).toList());

    final result = await saveReport(
      ReportBody(content: jsonString, path: path),
    );

    final rawMessage = result.message ?? '';
    final message =
        rawMessage.length > _maxLogMessageLength
            ? '${rawMessage.substring(0, _maxLogMessageLength)}...'
            : rawMessage;

    if (result.success) {
      logLine(
        '[JsonReporter] Report saved successfully. status=${result.statusCode}',
      );
    } else {
      logLine(
        '[JsonReporter] Failed to save report. status=${result.statusCode} message=$message',
      );
    }

    logLine('[JsonReporter] onAfterAll finished.');
  }

  @override
  Map<String, dynamic> toJson() {
    return {'features': _features.map((f) => f.toJson()).toList()};
  }
}
