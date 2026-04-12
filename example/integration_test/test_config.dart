import 'package:flutter/material.dart';
import 'package:flutter_bdd_suite/flutter_bdd_suite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'custom_hooks/debug_lifecycle_hook.dart';
import 'reporters/decorated_summary.dart';
import 'steps/common_steps.dart';
import 'steps/interaction_steps.dart';

final config = IntegrationTestConfig(
  setUp: (WidgetTester tester) async {
    await tester.binding.reassembleApplication();
  },
  onBindingInitialized: (IntegrationTestWidgetsFlutterBinding binding) async {
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
    debugPrint('Implement anything before the tests');
  },
  hooks: [DebugLifecycleHook()],
  reporters: [
    SummaryReporter(),
    DecoratedSummaryReporter(),
    JsonReporter(path: './report/report.json'),
  ],
  steps: [
    theApplicationIsLaunched(),
    iShouldReachDashboard(),
    theElementShouldBeVisible(),
    iShouldSeeText(),
    iShouldSeeMultipleTexts(),
    iEnterText(),
    iEnterTextDocString(),
    iInteractWithButton(),
  ],
);
