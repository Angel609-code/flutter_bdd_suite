import 'package:flutter_bdd_suite/lifecycle_listener.dart';
import 'package:flutter_bdd_suite/models/feature_model.dart';
import 'package:flutter_bdd_suite/models/scenario_model.dart';
import 'package:flutter_bdd_suite/steps/step_result.dart';
import 'package:flutter_bdd_suite/world/widget_tester_world.dart';

abstract class IntegrationHook implements LifecycleListener {
  @override
  int get priority => 0;

  @override
  Future<void> onBeforeAll() async {}

  @override
  Future<void> onFeatureStarted(FeatureInfo feature) async {}

  @override
  Future<void> onAfterAll() async {}

  @override
  Future<void> onBeforeScenario(ScenarioInfo scenario) async {}

  @override
  Future<void> onAfterScenario(String scenarioName) async {}

  @override
  Future<void> onBeforeStep(String stepText, WidgetTesterWorld world) async {}

  @override
  Future<void> onAfterStep(StepResult result, WidgetTesterWorld world) async {}
}
