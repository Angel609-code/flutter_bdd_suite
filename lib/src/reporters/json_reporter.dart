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

/// Identifiers for the synthetic `Background` element emitted in the JSON
/// report when background steps are present.
abstract final class _BackgroundElement {
  /// Display keyword used as the `keyword` field in the JSON element.
  static const keyword = 'Background';

  /// Element type used as the `type` field in the JSON element.
  static const type = 'background';

  /// Separator used when building the `id` field: `<featureId>;background`.
  static const idSuffix = 'background';
}

/// Maximum number of characters included in a log message for the report-save
/// response body.  Longer messages are truncated and suffixed with `...`.
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

  /// JSON model for the synthetic Background element of the current feature.
  ///
  /// Created lazily on the first background step result received after
  /// [onBeforeFeature] or [onAfterScenario].
  JsonScenario? _background;

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
    _background = null;
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
    final scenarioId = '$featureId;${scenario.scenarioName.toLowerCase().replaceAll(' ', '-')}';

    _currentScenario = JsonScenario(
      keyword: 'Scenario',
      type: 'scenario',
      id: scenarioId,
      name: scenario.scenarioName,
      line: scenario.line,
      tags: scenario.tags.map((t) => JsonTag(t, scenario.line - 1)).toList(),
    );
    _currentFeature!.elements.add(_currentScenario!);
  }

  /// Resets the background slot so that the next feature's background steps
  /// are captured in a fresh element.

  @override
  Future<void> onAfterScenario(ScenarioResult result) async {
    _inBackground = true;
    _background = null;
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

    if (_inBackground && _background == null) {
      final featureId = _currentFeature?.id ?? 'unknown-feature';
      _background = JsonScenario(
        keyword: _BackgroundElement.keyword,
        type: _BackgroundElement.type,
        name: '',
        id: '$featureId;${_BackgroundElement.idSuffix}',
        line: result.line - 1,
      );

      _currentFeature!.elements.add(_background!);
    }

    final stepText = result.stepText;
    final line = result.line;
    final parts = stepText.split(' ');
    final keyword = '${parts.first} ';
    final name = parts.skip(1).join(' ');
    String status;
    String? errorMessage;

    if (result is StepSuccess) {
      status = _StepStatus.passed;
    } else if (result is StepSkipped) {
      status = _StepStatus.skipped;
    } else if (result is StepUndefined) {
      status = _StepStatus.undefined;
    } else if (result is StepPending) {
      status = _StepStatus.pending;
    } else if (result is StepAmbiguous) {
      status = _StepStatus.ambiguous;
      errorMessage = '${result.error}';
    } else if (result is StepFailure) {
      status = _StepStatus.failed;
      errorMessage = '${result.error}';
    } else {
      status = _StepStatus.failed;
      errorMessage = 'Unknown step result type: ${result.runtimeType}';
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
      _background?.steps.add(jsonStep);
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
    final message = rawMessage.length > _maxLogMessageLength
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
