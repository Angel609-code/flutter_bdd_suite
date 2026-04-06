import 'package:flutter/material.dart';
import 'package:flutter_bdd_suite/integration_test_config.dart';
import 'package:flutter_bdd_suite/reporters/json_reporter.dart';
import 'package:flutter_bdd_suite/reporters/summary_reporter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'custom_hooks/debug_lifecycle_hook.dart';
import 'reporters/decorated_summary.dart';
import 'steps/app_steps.dart';
import 'steps/form_steps.dart';

final config = IntegrationTestConfig(
  appLauncher: (WidgetTester tester) async {
    await tester.binding.reassembleApplication();
  },
  onBindingInitialized: (IntegrationTestWidgetsFlutterBinding binding) async {
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
    debugPrint('Implement anything before the tests');
  },
  hooks: [
    DebugLifecycleHook(),
  ],
  reporters: [
    SummaryReporter(),
    DecoratedSummaryReporter(),
    JsonReporter(path: './report/report.json'),
  ],
  steps: [
    theApplicationIsLaunched(),
    theLoginScreenIsVisible(),
    theLoginFieldsArePresent(),
    iEnterValueInField(),
    iTapButton(),
    iShouldSee(),
    iShouldReachDashboard(),
    iFillField(),
    iShouldSeeElement(),
    iShouldNotSeeElement(),
    iShouldNotSee(),
    iShouldSeeMultipleTexts(),
    iTapElement(),
    iScrollToElement(),
    theElementIs(),
  ]
);
