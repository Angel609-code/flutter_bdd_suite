import 'package:flutter_bdd_suite/flutter_bdd_suite.dart';

import '../integration_endpoints/say_hello.dart';

class DebugLifecycleHook extends IntegrationHook {
  @override
  int get priority => 100;

  @override
  Future<void> onBeforeAll() async {
    final greeting = await sayHello();
    if (greeting.success) {
      logLine('Server says: ${greeting.message}');
    } else {
      logLine('Could not reach hello endpoint: ${greeting.message}');
    }

    logLine('[DEBUG HOOK] onBeforeAll');
  }

  @override
  Future<void> onAfterAll() async {
    logLine('[DEBUG HOOK] onAfterAll');
  }

  @override
  Future<void> onBeforeFeature(FeatureInfo feature) async {
    logLine('[DEBUG HOOK] onBeforeFeature');
  }

  @override
  Future<void> onBeforeScenario(ScenarioInfo scenario) async {
    logLine('[DEBUG HOOK] onBeforeScenario: ${scenario.scenarioName}');
  }

  @override
  Future<void> onAfterScenario(ScenarioResult result) async {
    logLine(
      '[DEBUG HOOK] onAfterScenario: ${result.scenarioName} (${result.status.name})',
    );
  }

  @override
  Future<void> onBeforeStep(BeforeStepContext context) async {
    logLine('[DEBUG HOOK] onBeforeStep: ${context.stepText}');
  }

  @override
  Future<void> onAfterStep(AfterStepContext context) async {
    logLine('[DEBUG HOOK] onAfterStep: ${context.result.stepText}');
  }
}
