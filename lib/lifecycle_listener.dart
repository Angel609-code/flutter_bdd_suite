import 'package:flutter_bdd_suite/models/feature_model.dart';
import 'package:flutter_bdd_suite/models/scenario_model.dart';
import 'package:flutter_bdd_suite/steps/step_result.dart';
import 'package:flutter_bdd_suite/world/widget_tester_world.dart';

abstract class LifecycleListener {
  int get priority => 0;

  Future<void> onBeforeAll() async {}

  Future<void> onAfterAll() async {}

  Future<void> onFeatureStarted(FeatureInfo feature) async {}

  Future<void> onAfterFeature(FeatureInfo feature) async {}

  Future<void> onBeforeScenario(ScenarioInfo scenario) async {}

  Future<void> onAfterScenario(ScenarioResult result) async {}

  Future<void> onBeforeStep(String stepText, WidgetTesterWorld world) async {}

  Future<void> onAfterStep(StepResult result, WidgetTesterWorld world) async {}
}
