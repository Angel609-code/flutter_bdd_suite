## 0.0.1

Initial release of `flutter_bdd_suite`.

### Features

- **Gherkin Parser:** Full English Gherkin syntax support including `Feature`, `Scenario`, `Scenario Outline`, `Background`, `Rule`, `Examples`, `Given`/`When`/`Then`/`And`/`But`/`*` step keywords, data tables, doc strings, and `@` tags.
- **Automatic Code Generation:** CLI command (`dart run flutter_bdd_suite:cli`) discovers `.feature` files, parses them, and generates one Dart `testWidgets` call per scenario using a Mustache template. A master runner (`all_integration_tests.dart`) is also generated to aggregate all tests.
- **`IntegrationTestConfig`:** Central configuration object accepting optional per-scenario `setUp`, optional `onBindingInitialized` callback, custom steps, hooks, and reporters.
- **Step Definition Framework:** Typed builder functions `generic` through `generic6` (0–6 captures) with support for `{string}`, `{int}`, `{float}`, and `{word}` placeholders. Data tables and doc-strings are delivered via the `WidgetTesterWorld` context object (`world.table`, `world.docString`).
- **Built-in Step:** `I fill the {string} field with {string}` — enters text into a widget found by `ValueKey`.
- **`WidgetTesterWorld`:** Context object passed to every step, providing access to `WidgetTester`, `IntegrationTestWidgetsFlutterBinding`, and a key-value attachment store for sharing state between steps.
- **Lifecycle Hooks:** `IntegrationHook` base class with `onBeforeAll`, `onAfterAll`, `onFeatureStarted`, `onBeforeScenario`, `onAfterScenario`, `onBeforeStep`, and `onAfterStep` callbacks. Hooks are executed in descending priority order.
- **Reporters:**
  - `SummaryReporter` — prints scenario pass/fail/skip counts and elapsed time to the terminal.
  - `JsonReporter` — generates a Cucumber-compatible JSON report for use with `cucumber-html-reporter`.
- **Bridge Server:** `IntegrationTestServer` (host-side) and `bridgeGet`/`bridgePostJson` helpers (device-side) enable device-to-host HTTP communication during tests — useful for persisting report files and triggering host-side actions.
- **Tag Filtering:** Boolean tag expressions (`@tag`, `not @tag`, `@a and @b`, `@a or @b`, parenthesized groups) via the `--tags` CLI flag.
- **Test Ordering:** `--order none|alphabetically|basename|reverse|random[:seed]` for deterministic or randomized execution.
- **`--mode test` (default):** Wraps `flutter test` for Android, iOS, macOS, Linux, and Windows.
- **`--mode drive`:** Wraps `flutter drive` for web (Chrome) testing.
- **`--coverage`:** Enables `flutter test --coverage` in test mode; produces `coverage/lcov.info`.
