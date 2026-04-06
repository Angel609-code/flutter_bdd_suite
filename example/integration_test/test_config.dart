import 'package:example/main.dart';
import 'package:example/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gherkin_parser/integration_test_config.dart';
import 'package:flutter_gherkin_parser/reporters/json_reporter.dart';
import 'package:flutter_gherkin_parser/reporters/summary_reporter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'custom_hooks/debug_lifecycle_hook.dart';
import 'reporters/decorated_summary.dart';
import 'steps/and_enter_text_step.dart';
import 'steps/and_print_non_grouping_value_step.dart';
import 'steps/and_print_table_step.dart';
import 'steps/then_read_text_step.dart';
import 'steps/when_click_in_step.dart';

final config = IntegrationTestConfig(
  appLauncher: (WidgetTester tester) async {
    themeNotifier.value = ThemeMode.light;
    await tester.binding.reassembleApplication();
    await tester.pumpWidget(const BddExampleApp());

    await tester.pumpAndSettle();
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
    thenReadTextStep(),
    andPrintTable(),
    whenClickWidgetStep(),
    andPrintNonGroupingValue(),
    andPrintNonGroupingValue3(),
    andEnterTextWithLookahead(),
    andHaveItemsInCategory(),
    andPrintWithOptionalHeightAndAge(),
    andMatchMultipleGroups(),
    andProcessMultilineText(),
    andProcessSixCaptures(),
  ]
);
