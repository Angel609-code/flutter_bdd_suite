import 'dart:convert' show jsonEncode;

import 'package:flutter_bdd_suite/src/models/background_model.dart';
import 'package:flutter_bdd_suite/src/models/scenario_model.dart';

/// Parsed representation of a Gherkin `Feature` block as produced by the
/// Gherkin parser.
///
/// This is the internal model used while building the parse tree; lifecycle
/// callbacks use [FeatureInfo] (a lighter data-transfer object) instead.
class Feature {
  /// The feature title as written after the `Feature:` keyword.
  final String name;

  /// Relative URI of the `.feature` file (e.g. `features/auth/login.feature`).
  final String uri;

  /// Line number of the `Feature:` keyword in the feature file (1-based).
  final int line;

  /// Gherkin tags applied at the feature level (e.g. `['@auth', '@regression']`).
  final List<String> tags;

  /// Optional `Background:` block that precedes the scenarios in this feature.
  Background? background;

  /// Scenarios (and Scenario Outline rows) belonging to this feature in
  /// declaration order.
  final List<Scenario> scenarios = [];

  Feature({
    required this.name,
    required this.uri,
    required this.line,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'uri': uri,
      'line': line,
      'tags': tags,
      if (background != null) 'background': background!.toJson(),
      'scenarios': scenarios.map((scenario) => scenario.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

/// Lightweight data-transfer object that carries the information the test
/// runner and lifecycle listeners need for a single feature file.
///
/// Passed to [LifecycleListener.onBeforeFeature] and
/// [LifecycleListener.onAfterFeature].
class FeatureInfo {
  /// The feature title as written after the `Feature:` keyword.
  final String featureName;

  /// Relative URI of the `.feature` file (e.g. `features/auth/login.feature`).
  final String uri;

  /// Line number of the `Feature:` keyword in the feature file (1-based).
  final int line;

  /// Gherkin tags applied at the feature level (e.g. `['@auth', '@regression']`).
  final List<String> tags;

  FeatureInfo({
    required this.featureName,
    required this.uri,
    required this.line,
    this.tags = const [],
  });
}
