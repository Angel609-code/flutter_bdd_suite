import 'dart:convert';
import 'package:flutter_bdd_suite/logger.dart';
import 'package:flutter_bdd_suite/models/feature_model.dart';
import 'package:flutter_bdd_suite/models/json_step_model.dart';
import 'package:flutter_bdd_suite/models/report_model.dart';
import 'package:flutter_bdd_suite/models/scenario_model.dart';
import 'package:flutter_bdd_suite/reporters/integration_reporter.dart';
import 'package:flutter_bdd_suite/server/integration_endpoints.dart';
import 'package:flutter_bdd_suite/steps/step_result.dart';
import 'package:flutter_bdd_suite/world/widget_tester_world.dart';

/// Creates a JSON file with the results of the test run.
///
/// This JSON file can be used by the [cucumber-html-reporter](https://www.npmjs.com/package/cucumber-html-reporter)
/// npm package to create a comprehensive HTML report.
///
/// This reporter was inspired by the reporting implementation in the `flutter_gherkin` package,
/// but has been specifically adapted for `integration_test` to replace the older `flutter_driver` approach.
class JsonReporter extends IntegrationReporter {
  final List<JsonFeature> _features = [];
  JsonScenario? _currentScenario;
  JsonFeature? _currentFeature;

  JsonScenario? _background;
  bool? _inBackground;

  JsonReporter({required super.path});

  @override
  Future<void> onFeatureStarted(FeatureInfo feature) async {
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

  @override
  Future<void> onBeforeScenario(ScenarioInfo scenario) async {
    _inBackground = false;

    final id = scenario.scenarioName.toLowerCase().replaceAll(' ', '-');
    final scenarioId = '${_currentFeature!.id};$id';
    _currentScenario = JsonScenario(
      id: scenarioId,
      name: scenario.scenarioName,
      line: scenario.line,
      tags: scenario.tags.map((t) => JsonTag(t, scenario.line - 1)).toList(),
    );
    _currentFeature!.elements.add(_currentScenario!);
  }

  @override
  Future<void> onAfterScenario(ScenarioResult result) async {
    _inBackground = true;
    _background = null;
  }

  @override
  Future<void> onAfterStep(StepResult result, WidgetTesterWorld world) async {
    if (_inBackground == true && _background == null) {
      _background = JsonScenario(
        id: '${_currentFeature!.id};background',
        keyword: 'Background',
        name: '',
        type: 'background',
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
      status = 'passed';
    } else if (result is StepSkipped) {
      status = 'skipped';
    } else if (result is StepUndefined) {
      status = 'undefined';
    } else if (result is StepPending) {
      status = 'pending';
    } else if (result is StepAmbiguous) {
      status = 'ambiguous';
      errorMessage = '${result.error}';
    } else if (result is StepFailure) {
      status = 'failed';
      errorMessage = '${result.error}';
    } else {
      status = 'failed';
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

    if (_inBackground == true) {
      _background?.steps.add(jsonStep);
    } else {
      _currentScenario?.steps.add(jsonStep);
    }
  }

  @override
  Future<void> onAfterAll() async {
    final jsonString = jsonEncode(_features.map((f) => f.toJson()).toList());
    logLine(
      '[JsonReporter] onAfterAll started. features=${_features.length} path=$path',
    );

    final result = await saveReport(
      ReportBody(content: jsonString, path: path),
    );

    final rawMessage = result.message ?? '';
    final message =
        rawMessage.length > 300
            ? '${rawMessage.substring(0, 300)}...'
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
  Future<void> onBeforeAll() async {}
  @override
  Future<void> onBeforeStep(String stepText, WidgetTesterWorld world) async {}
  @override
  Future<void> onAfterFeature(FeatureInfo feature) async {}

  @override
  int get priority => 0;

  @override
  Map<String, dynamic> toJson() {
    return {'features': _features.map((f) => f.toJson()).toList()};
  }
}
