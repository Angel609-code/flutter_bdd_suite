// ignore_for_file: avoid_print
import 'package:flutter_gherkin_parser/hooks/integration_hook.dart';
import 'package:flutter_gherkin_parser/models/models.dart';
import 'package:flutter_gherkin_parser/steps/step_result.dart';
import 'package:flutter_gherkin_parser/world/widget_tester_world.dart';

import '../integration_endpoints/say_hello.dart';

class DebugLifecycleHook extends IntegrationHook {
  @override
  int get priority => 100;

  @override
  Future<void> onBeforeAll() async {
    final greeting = await sayHello();
    if (greeting.success) {
      print('🟢 Server says: ${greeting.message}');
    } else {
      print('🔴 Could not reach hello endpoint: ${greeting.message}');
    }

    print('[DEBUG HOOK] 🟡 onBeforeAll');
  }

  @override
  Future<void> onAfterAll() async {
    print('[DEBUG HOOK] 🔴 onAfterAll');
  }

  @override
  Future<void> onFeatureStarted(FeatureInfo feature) async {
    print('[DEBUG HOOK] 🟠 onFeatureStarted');
  }

  @override
  Future<void> onBeforeScenario(ScenarioInfo scenario) async {
    print('[DEBUG HOOK] 🟡 onBeforeScenario: ${scenario.scenarioName}');
  }

  @override
  Future<void> onAfterScenario(String scenarioName) async {
    print('[DEBUG HOOK] 🔵 onAfterScenario: $scenarioName');
  }

  @override
  Future<void> onBeforeStep(String stepText, WidgetTesterWorld world) async {
    print('[DEBUG HOOK] 🟡 onBeforeStep: $stepText');
  }

  @override
  Future<void> onAfterStep(StepResult result, WidgetTesterWorld world) async {
    print('[DEBUG HOOK] 🟢 onAfterStep: ${result.stepText}');
  }
}
