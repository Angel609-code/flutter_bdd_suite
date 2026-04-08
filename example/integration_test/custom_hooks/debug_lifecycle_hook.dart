import 'package:flutter_bdd_suite/hooks/integration_hook.dart';
import 'package:flutter_bdd_suite/logger.dart';
import 'package:flutter_bdd_suite/models/models.dart';
import 'package:flutter_bdd_suite/steps/step_result.dart';
import 'package:flutter_bdd_suite/world/widget_tester_world.dart';

import '../integration_endpoints/say_hello.dart';

class DebugLifecycleHook extends IntegrationHook {
  @override
  int get priority => 100;

  @override
  Future<void> onBeforeAll() async {
    final greeting = await sayHello();
    if (greeting.success) {
      logLine('🟢 Server says: ${greeting.message}');
    } else {
      logLine('🔴 Could not reach hello endpoint: ${greeting.message}');
    }

    logLine('[DEBUG HOOK] 🟡 onBeforeAll');
  }

  @override
  Future<void> onAfterAll() async {
    logLine('[DEBUG HOOK] 🔴 onAfterAll');
  }

  @override
  Future<void> onFeatureStarted(FeatureInfo feature) async {
    logLine('[DEBUG HOOK] 🟠 onFeatureStarted');
  }

  @override
  Future<void> onBeforeScenario(ScenarioInfo scenario) async {
    logLine('[DEBUG HOOK] 🟡 onBeforeScenario: ${scenario.scenarioName}');
  }

  @override
  Future<void> onAfterScenario(String scenarioName) async {
    logLine('[DEBUG HOOK] 🔵 onAfterScenario: $scenarioName');
  }

  @override
  Future<void> onBeforeStep(String stepText, WidgetTesterWorld world) async {
    logLine('[DEBUG HOOK] 🟡 onBeforeStep: $stepText');
  }

  @override
  Future<void> onAfterStep(StepResult result, WidgetTesterWorld world) async {
    logLine('[DEBUG HOOK] 🟢 onAfterStep: ${result.stepText}');
  }
}
