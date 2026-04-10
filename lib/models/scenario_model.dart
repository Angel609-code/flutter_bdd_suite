import 'dart:convert' show jsonEncode;

import 'package:flutter_bdd_suite/models/step_model.dart';

class Scenario {
  final String name;
  final int line;
  final List<String> tags;
  final List<Step> steps = [];

  Scenario({required this.name, required this.line, this.tags = const []});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'line': line,
      'tags': tags,
      'steps': steps.map((step) => step.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

class ScenarioInfo {
  final String scenarioName;
  final int line;
  final List<String> tags;
  final List<String> steps;

  ScenarioInfo({
    required this.scenarioName,
    required this.line,
    this.tags = const [],
    this.steps = const [],
  });
}

/// The execution outcome of a scenario after all its steps have run.
enum ScenarioExecutionStatus {
  /// Every step in the scenario completed without error.
  passed,

  /// At least one step threw an error or assertion failure.
  failed,

  /// The scenario was skipped, typically because a prior background step failed.
  skipped,
}

/// Rich context object passed to [LifecycleListener.onAfterScenario].
///
/// Provides both the original [ScenarioInfo] and the final [status] so that
/// hooks and reporters can react to the outcome without having to track per-step
/// state themselves.
class ScenarioResult {
  /// The scenario that just finished executing.
  final ScenarioInfo scenario;

  /// The overall outcome of the scenario.
  final ScenarioExecutionStatus status;

  const ScenarioResult({required this.scenario, required this.status});

  /// Convenience accessor – mirrors [ScenarioInfo.scenarioName].
  String get scenarioName => scenario.scenarioName;
}
