# flutter_bdd_suite

`flutter_bdd_suite` is a BDD (Behavior-Driven Development) companion tool for Flutter, inspired by the [Cucumber](https://cucumber.io/) philosophy. Write human-readable Gherkin feature files and let the package automatically convert them into executable Flutter integration tests — with no boilerplate.

Built natively on Flutter's `integration_test` package, it gives you direct access to the widget tree, lifecycle hooks, extensible step definitions, multiple reporters, and a host-bridge server for device-to-host communication — all in one coherent pipeline.

---

## Table of Contents

- [Features](#features)
- [Getting Started](#getting-started)
  - [Installation](#installation)
  - [Project Structure](#project-structure)
- [Gherkin Syntax Support](#gherkin-syntax-support)
  - [Core Keywords](#core-keywords)
  - [Scenario Outlines & Examples](#scenario-outlines--examples)
  - [Background & Rules](#background--rules)
  - [Data Tables](#data-tables)
  - [Doc Strings](#doc-strings)
  - [Tags](#tags)
- [Configuration](#configuration)
- [Running Tests](#running-tests)
  - [Test Mode (Mobile & Desktop)](#test-mode-mobile--desktop)
  - [Drive Mode (Web)](#drive-mode-web)
  - [All CLI Options](#all-cli-options)
- [Code Generation](#code-generation)
- [Coverage](#coverage)
- [Step Definitions](#step-definitions)
  - [Built-in Steps](#built-in-steps)
  - [Custom Steps](#custom-steps)
  - [Pattern Syntax](#pattern-syntax)
  - [Working with Tables in Steps](#working-with-tables-in-steps)
- [Test World](#test-world)
- [Hooks](#hooks)
- [Reporters](#reporters)
  - [SummaryReporter](#summaryreporter)
  - [JsonReporter](#jsonreporter)
  - [Custom Reporters](#custom-reporters)
- [Bridge Server](#bridge-server)
  - [Host-Side Server](#host-side-server)
  - [Device-Side HTTP Client](#device-side-http-client)
  - [Custom Endpoints](#custom-endpoints)
- [Tag Filtering](#tag-filtering)
- [Additional Information](#additional-information)

---

## Features

- **BDD & Gherkin:** Follows the [Cucumber BDD approach](https://cucumber.io/docs/) and the full [Gherkin syntax reference](https://cucumber.io/docs/gherkin/reference) (English keywords).
- **Native Integration Test:** Built on Flutter's `integration_test` package — no `flutter_driver` dependencies.
- **Automatic Code Generation:** Converts `.feature` files into executable Dart integration test files with a single CLI command.
- **Rich Gherkin Parsing:** Full support for Scenario Outlines, Background, Rules, data tables, doc strings, and tags.
- **Flexible Step Definitions:** Typed step builders (`generic` through `generic6`) with `{string}`, `{int}`, `{float}`, `{word}` placeholders and arbitrary regex captures. Data tables and doc-strings are accessible via the `TestWorld` context object.
- **Lifecycle Hooks:** Before/after hooks at the All, Feature, Scenario, and Step levels with priority-based execution.
- **Extensible Reporters:** Built-in summary and Cucumber-compatible JSON reporters. Compose your own by extending `IntegrationReporter`.
- **Host Bridge Server:** A built-in local HTTP server runs on your host machine while tests execute on any platform (Android, iOS, macOS, Linux, Windows, or Web). Device-side tests call it via HTTP to perform host-side actions that are impossible from inside the test process — for example, saving report files to disk (including from web where the device has no access to the host file system), seeding or resetting a database, calling external APIs, triggering CI scripts, or any other operation that requires the host environment.
- **Tag Filtering:** Boolean tag expressions (`@tag`, `not @tag`, `@a and @b`, `@a or @b`) to run only the scenarios you want.
- **Test Ordering:** Run tests alphabetically, by basename, in reverse, or with a random seed for flakiness detection.
- **CI Ready:** Generates Cucumber JSON output compatible with `cucumber-html-reporter` for beautiful HTML reports.

---

## Getting Started

### Installation

Add `flutter_bdd_suite` to your `dev_dependencies` in `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_bdd_suite: ^0.0.1
```

Run `flutter pub get`.

### Project Structure

After setup, your project should look like this:

```
my_app/
├── lib/
│   └── main.dart
├── integration_test/
│   ├── features/                  # Your .feature files go here
│   │   └── auth/
│   │       └── login.feature
│   ├── generated/                 # Auto-generated — do not edit manually
│   ├── steps/                     # Your custom step definitions
│   ├── hooks/                     # Your custom lifecycle hooks
│   ├── reporters/                 # Your custom reporters (optional)
│   ├── integration_endpoints/     # Device-side wrappers for bridge endpoints
│   │   └── endpoints.dart
│   ├── bridge_setup.dart          # Registers custom host-side bridge endpoints
│   ├── test_config.dart           # Suite configuration entry point
│   └── all_integration_tests.dart # Auto-generated master runner
└── test_driver/
    └── integration_test.dart      # Required for web (drive mode) only
```

---

## Gherkin Syntax Support

> **Note:** Only English Gherkin keywords are currently supported.

### Core Keywords

```gherkin
Feature: User Authentication
  As a registered user
  I want to log in to the application
  So that I can access my account

  Scenario: Successful login
    Given I am on the login screen
    When I fill the "username" field with "alice"
    And I fill the "password" field with "secret"
    And I tap the login button
    Then I should see the home screen
```

Supported step keywords: `Given`, `When`, `Then`, `And`, `But`, `*`.

### Scenario Outlines & Examples

Run the same scenario with multiple data rows using `Scenario Outline` and `Examples`:

```gherkin
Feature: Login Validation

  Scenario Outline: Login with various credentials
    Given I am on the login screen
    When I fill the "username" field with "<username>"
    And I fill the "password" field with "<password>"
    And I tap the login button
    Then I should see "<result>"

    Examples:
      | username | password | result        |
      | alice    | secret   | home screen   |
      | bob      | wrong    | error message |
      | ""       | ""       | error message |
```

Each row in `Examples` generates a separate `testWidgets` call.

### Background & Rules

Use `Background` to run steps before every scenario in a feature:

```gherkin
Feature: Employee Management

  Background:
    Given I am logged in as admin
    And I am on the home screen

  Scenario: View employee list
    Then I should see the employee list

  Scenario: Add an employee
    When I tap the add employee button
    Then I should see the add employee form
```

Use `Rule` to group related scenarios with their own optional `Background`:

```gherkin
Feature: Dashboard

  Rule: Authenticated users
    Background:
      Given I am logged in

    Scenario: See dashboard
      Then I should see the dashboard

  Rule: Unauthenticated users
    Scenario: Redirect to login
      Then I should be redirected to login
```

### Data Tables

Attach structured data directly to a step. The table is automatically parsed into a `GherkinTable` object:

```gherkin
Scenario: Add multiple employees
  Given the following employees exist:
    | name    | role      | salary |
    | Alice   | Developer | 90000  |
    | Bob     | Designer  | 80000  |
```

In your step definition, access the table via the `ctx.table` property (see [Working with Tables in Steps](#working-with-tables-in-steps)).

### Doc Strings

Embed multi-line text in a step using triple-quoted strings or triple backticks:

```gherkin
Scenario: Display terms and conditions
  When I open the terms dialog
  Then I should see the text:
    """
    By using this app you agree to our Terms of Service.
    All data is processed in accordance with our Privacy Policy.
    """
```

### Tags

Annotate features and scenarios with `@` tags:

```gherkin
@smoke @authentication
Feature: Login

  @happy-path
  Scenario: Successful login
    ...

  @negative @wip
  Scenario: Failed login
    ...
```

Use [tag expressions](#tag-filtering) with the `--tags` CLI flag to run only matching scenarios.

---

## Configuration

Create a Dart file (typically `integration_test/test_config.dart`) that exports a top-level `config` variable of type `IntegrationTestConfig`:

```dart
import 'package:flutter_bdd_suite/integration_test_config.dart';
import 'package:flutter_bdd_suite/reporters/json_reporter.dart';
import 'package:flutter_bdd_suite/reporters/summary_reporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/main.dart' as app;
import 'hooks/my_hook.dart';
import 'steps/my_steps.dart';

final config = IntegrationTestConfig(
  // Optional: run once per scenario before Background/Scenario steps
  setUp: (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();
  },

  // Optional: called once after the binding is initialized
  onBindingInitialized: (binding) async {
    // e.g. configure your DI container
  },

  // Custom step definitions
  steps: [
    myCustomStep(),
    anotherStep(),
  ],

  // Lifecycle hooks
  hooks: [
    MyHook(),
  ],

  // Result reporters
  reporters: [
    SummaryReporter(),
    JsonReporter(path: 'test_report.json'),
  ],
);
```

| Property | Type | Description |
|---|---|---|
| `setUp` | `Future<void> Function(WidgetTester)?` | Optional callback run once per scenario before Background and Scenario steps. Use this to reset state and optionally mount the app. |
| `onBindingInitialized` | `Future<void> Function(IntegrationTestWidgetsFlutterBinding)?` | Optional setup hook run once after binding initialization. |
| `steps` | `List<StepDefinitionGeneric>` | Custom step definitions to add to the registry. |
| `hooks` | `List<IntegrationHook>` | Lifecycle hooks executed around tests. |
| `reporters` | `List<IntegrationReporter>` | Result reporters. |

### Scenario Setup Strategies

The framework supports two valid startup styles. Choose one and apply it consistently.

1. **Config-Driven Startup**

Use `setUp` to reset state and mount the app before each scenario.

```dart
final config = IntegrationTestConfig(
  setUp: (WidgetTester tester) async {
    // Example: reset in-memory state before each scenario.
    // getIt.reset();

    app.main();
    await tester.pumpAndSettle();
  },
);
```

2. **Step-Driven Startup**

Leave `setUp` as `null` (or keep it only for memory/state resets) and mount the UI in an explicit Gherkin step.

```dart
StepDefinitionGeneric theAppIsLaunched() {
  return generic<WidgetTesterWorld>(
    r'the application is launched',
    (world) async {
      await ctx.tester.pumpWidget(const BddExampleApp());
      await ctx.tester.pumpAndSettle();
    },
  );
}
```

### Execution Order

For each scenario, execution order is:

1. `IntegrationTestConfig.setUp` (if provided)
2. Background steps
3. Scenario steps

This keeps setup separate from hook lifecycle callbacks like `onBeforeScenario` / `onAfterScenario`.

---

## Running Tests

The `cli` command is a thin orchestration wrapper. It handles two things:

1. **Generation** — Discovers `.feature` files, applies any filters (`--tags`, `--pattern`, `--order`), and generates the Dart test bindings.
2. **Execution** — Runs native Flutter tooling (`flutter test` or `flutter drive`) based on `--mode`.

### How Argument Forwarding Works

- Arguments **before** `--` are consumed by `flutter_bdd_suite:cli`.
- Arguments **after** `--` are forwarded to the underlying Flutter command.
- `--mode` is a wrapper flag and selects which native command is executed internally:
  - `--mode test` -> `flutter test ...`
  - `--mode drive` -> `flutter drive ...`

In other words, this wrapper chooses the Flutter command, and the passthrough part after `--` is where you place normal/native Flutter flags.

Command shapes used internally:

- **Test mode:** `flutter test [bridge dart-defines] [passthrough args] [generated target if none provided]`
- **Drive mode:** `flutter drive [bridge dart-defines] [passthrough args]`

For drive mode, pass required Flutter drive flags yourself (typically `--driver` and `--target`) after `--`.

### Test Mode (Mobile & Desktop)

The default mode. Works on Android, iOS, macOS, Linux, and Windows — any platform supported by `flutter test`.

```bash
dart run flutter_bdd_suite:cli --mode test --config test_config.dart -- -d macos --coverage
```

This runs generation, then executes native Flutter test with your passthrough flags:

```bash
flutter test -d macos --coverage integration_test/all_integration_tests.dart
```

### Drive Mode (Web)

Web integration tests require `flutter drive`.

```bash
dart run flutter_bdd_suite:cli \
  --config test_config.dart \
  --mode drive \
  -- \
  --driver test_driver/integration_test.dart \
  --target integration_test/all_integration_tests.dart \
  -d chrome
```

This runs generation, then executes native Flutter drive with the forwarded flags:

```bash
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/all_integration_tests.dart \
  -d chrome
```

Create `test_driver/integration_test.dart` with:

```dart
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
```

### All CLI Options

```
dart run flutter_bdd_suite:cli [options]
```

| Flag | Default | Description |
|---|---|---|
| `--config <path>` | _(required)_ | Path to your `IntegrationTestConfig` Dart file. |
| `--mode test\|drive` | `test` | Wrapper mode that chooses native `flutter test` or `flutter drive`. |
| `--order none\|alphabetically\|basename\|reverse\|random[:seed]` | `none` | Order in which feature files are executed. |
| `--pattern <regex>` | _(none)_ | Filter feature files by a regex on their file path. |
| `--tags <expression>` | _(none)_ | Run only scenarios matching a boolean tag expression. |
| `--dry-run` | `false` | Generate test files only; do not execute them. |
| `--generate-only` | `false` | Same as `--dry-run`. |
| `--command <shell>` | _(auto)_ | Replace the entire flutter invocation with a custom shell command. |
| `--bridge-mode plain\|auto\|bridge` | `auto` | Bridge startup strategy. |
| `--bridge-host <host>` | _(platform default)_ | Override the host address the bridge binds to. |
| `--bridge-port <port>` | `9876` | Override the port the bridge listens on. |
| `--no-bridge` | `false` | Disable the bridge server entirely. |
| `--bridge-script <path>` | _(none)_ | Path to a custom script that starts the bridge. |
| `--bridge-setup <path>` | _(none)_ | Path to a Dart file that registers custom bridge endpoints. |

Use `--` to pass native Flutter command arguments (for example `--coverage`, `-d chrome`, `--web-renderer=html`, `--driver=...`, `--target=...`).

**Examples:**

```bash
# Run only @smoke scenarios, randomized, with coverage
dart run flutter_bdd_suite:cli \
  --config test_config.dart \
  --tags "@smoke" \
  --order random \
  -- --coverage

# Run only feature files matching 'auth', generate without running
dart run flutter_bdd_suite:cli \
  --config test_config.dart \
  --pattern auth \
  --dry-run

# Web run on Chrome, pass extra flutter args
dart run flutter_bdd_suite:cli \
  --config test_config.dart \
  --mode drive \
  -- \
  --driver test_driver/integration_test.dart \
  --target integration_test/all_integration_tests.dart \
  -d chrome \
  --web-renderer=html
```

---

## Code Generation

Every time you run `cli`, the pipeline:

1. Discovers all `*.feature` files under `integration_test/features/`.
2. Parses each file with the built-in `FeatureParser` (handles outlines, backgrounds, rules, tables, doc strings, tags).
3. Deletes the existing `integration_test/generated/` directory.
4. Renders a Dart test file for each feature using a Mustache template — one `testWidgets()` per scenario.
5. Generates `integration_test/all_integration_tests.dart` — a master runner that imports every generated file.

The generated files are **deterministic** and can be committed to version control if desired, but they are always regenerated on the next run, so it is generally safe to add `integration_test/generated/` to `.gitignore`.

---

## Coverage

```bash
dart run flutter_bdd_suite:cli \
  --config test_config.dart \
  -- --coverage
```

> **Important:** `--coverage` only works with `--mode test`. The `flutter drive` command does not support coverage.

Once the run completes, a `coverage/lcov.info` file is generated. To convert it to a human-readable HTML report you need the `genhtml` tool, which is part of the **LCOV** package.

**Installing LCOV / genhtml:**

| Platform | Command |
|---|---|
| macOS | `brew install lcov` |
| Ubuntu / Debian | `sudo apt-get install lcov` |
| Fedora / RHEL | `sudo dnf install lcov` |
| Windows | Use [WSL](https://learn.microsoft.com/en-us/windows/wsl/) and then `sudo apt-get install lcov`, or find a Windows LCOV build. |

Once installed, generate and open the HTML report:

```bash
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html        # macOS
xdg-open coverage/html/index.html   # Linux
start coverage/html/index.html       # Windows
```

---

## Step Definitions

### Built-in Steps

The package ships with one built-in step, available by default without any configuration:

| Pattern | Description |
|---|---|
| `I fill the {string} field with {string}` | Finds a widget by `ValueKey`, enters text, and pumps the UI. |

### Custom Steps

Define custom steps using the typed `generic` builder functions. Each function corresponds to the number of captures (arguments) extracted from the step text:

```dart
import 'package:flutter_bdd_suite/flutter_bdd_suite.dart';

// 0 captures — matches the literal string exactly
StepDefinitionGeneric tapLoginButton() => step(
  'I tap the login button',
  (StepContext ctx) async {
    await ctx.tester.tap(find.byKey(const ValueKey('login_button')));
    await ctx.tester.pumpAndSettle();
  },
);

// 1 capture — {string} extracts a quoted value
StepDefinitionGeneric iSeeText() => step1(
  'I should see {string}',
  (String text, StepContext ctx) async {
    expect(find.text(text), findsOneWidget);
  },
);

// 2 captures — two {string} placeholders
StepDefinitionGeneric fillField() => step2(
  'I fill the {string} field with {string}',
  (String key, String value, StepContext ctx) async {
    await ctx.tester.enterText(find.byKey(ValueKey(key)), value);
    await ctx.tester.pumpAndSettle();
  },
);

// Manual regex capture — use a regex group directly in the pattern
StepDefinitionGeneric waitSeconds() => step1(
  r'I wait (\d+) seconds?',
  (String seconds, StepContext ctx) async {
    await Future.delayed(Duration(seconds: int.parse(seconds)));
  },
);
```

Register your steps in the config:

```dart
final config = IntegrationTestConfig(
  setUp: ...,
  steps: [
    tapLoginButton(),
    iSeeText(),
    fillField(),
    waitSeconds(),
  ],
);
```

Builders `generic` through `generic6` are available, supporting 0 to 6 captures respectively.

### Pattern Syntax

Patterns are strings that get compiled to `RegExp` for matching. The following constructs are supported:

| Syntax | Example | Description |
|---|---|---|
| `{string}` | `fill the {string} field` | Captures a double-quoted value. The quotes are stripped. |
| `{int}` | `I wait {int} seconds` | Captures an unquoted integer and parses it to `int`. |
| `{float}` | `price is {float}` | Captures an unquoted decimal and parses it to `double`. |
| `{word}` | `status is {word}` | Captures a single non-whitespace word. |
| `(foo\|bar)` | `I (enable\|disable) the feature` | Manual capturing group — value passed as a `String`. |
| `(\d+)` | `I wait (\d+) seconds` | Manual regex capture — value passed as a `String`. |
| `(?:optional)?` | `I tap the (?:big )?button` | Non-capturing optional literal — not passed to the step function. |
| `(?=...)` / `(?!...)` | Lookahead/lookbehind | Supported, not counted as captures. |

> **Note:** The total number of capturing groups in the pattern must match the `generic` variant you use (`generic1` → 1, `generic2` → 2, etc.).

### Working with Tables in Steps

Data tables are **first-class properties** on the `Step` model — they are never embedded in the step text string. When the runner matches a step, it attaches the table or doc-string to the `WidgetTesterWorld` context object.

You can access them inside any `generic` (and `genericN`) builder via the `table` and `docString` properties.

```dart
// Step with no string captures, but accesses the attached table
StepDefinitionGeneric givenEmployeesExist() => generic<WidgetTesterWorld>(
  'the following employees exist',
  (StepContext ctx) async {
    // Access the table directly from the world context
    final table = ctx.table;
    
    // Iterate rows as Map<String, String?>
    // (the Gherkin spec ensures table! will not be null if the step has a table)
    for (final row in table!.asMap()) {
      print('Name: ${row['name']}, Role: ${row['role']}');
    }
  },
);

// Step with captures AND multiline content
StepDefinitionGeneric givenDataForEntity() => generic1<String, WidgetTesterWorld>(
  'the following data exists for {string}',
  (String entity, StepContext ctx) async {
    // Access via world.multilineArg (the raw union type) if needed,
    // or use the shortcuts:
    if (ctx.table != null) {
      print('Handling table for $entity');
    } else if (world.docString != null) {
      print('Handling docstring: ${world.docString}');
    }
  },
);
```

The `ctx.table` and `world.docString` properties are `null` when the step in the feature file has no attached data. Since they are properties of the context object, you don't need to change your function signature to use them.

`GherkinTable` API:

| Method / Property | Description |
|---|---|
| `header` | The header row as a `TableRow` (column names). |
| `rows` | All data rows as `List<TableRow>`. |
| `asMap()` | Returns `Iterable<Map<String, String?>>` — each row as a column-name-to-value map. |
| `clone()` | Deep-copies the table. |

---

## Test World

The **World** is a context object that lives for the duration of a single scenario. It is passed to every step function and gives you access to:

- `ctx.tester` — the Flutter `WidgetTester` for interacting with the widget tree.
- `world.binding` — the `IntegrationTestWidgetsFlutterBinding`.
- `world.setAttachment<T>(key, value)` / `world.getAttachment<T>(key)` — share state between steps within the same scenario.

**Example — sharing state between steps:**

```dart
// Step 1: store a value
StepDefinitionGeneric iRememberTheText() => step1(
  'I remember the text {string}',
  (String text, StepContext ctx) async {
    world.setAttachment('remembered_text', text);
  },
);

// Step 2: retrieve the stored value
StepDefinitionGeneric iVerifyTheText() => step(
  'I verify the remembered text',
  (StepContext ctx) async {
    final text = world.getAttachment<String>('remembered_text');
    expect(find.text(text!), findsOneWidget);
  },
);
```

---

## Hooks

Hooks let you execute custom Dart code at specific points in the test lifecycle. Create a class that extends `IntegrationHook`:

```dart
import 'package:flutter_bdd_suite/hooks/integration_hook.dart';
import 'package:flutter_bdd_suite/models/models.dart';
import 'package:flutter_bdd_suite/steps/step_result.dart';
import 'package:flutter_bdd_suite/world/widget_tester_world.dart';

class MyHook extends IntegrationHook {
  @override
  int get priority => 10; // higher priority runs first

  @override
  Future<void> onBeforeAll() async {
    // Runs once before the entire test suite starts
  }

  @override
  Future<void> onAfterAll() async {
    // Runs once after the entire test suite finishes
  }

  @override
  Future<void> onFeatureStarted(FeatureInfo feature) async {
    print('Starting feature: ${feature.featureName}');
  }

  @override
  Future<void> onBeforeScenario(ScenarioInfo scenario) async {
    // Seed database, reset app state, etc.
  }

  @override
  Future<void> onAfterScenario(String scenarioName) async {
    // Clean up resources
  }

  @override
  Future<void> onBeforeStep(String stepText, StepContext ctx) async {
    // Prepare for a step (e.g., clear a text field)
  }

  @override
  Future<void> onAfterStep(StepResult result, StepContext ctx) async {
    // React to a step result (e.g., take a screenshot on failure)
    if (result is StepFailure) {
      // capture screenshot, log error, etc.
    }
  }
}
```

**Lifecycle order:**

```
onBeforeAll
  └─ [for each feature]
       onFeatureStarted
       └─ [for each scenario]
            onBeforeScenario
            └─ [for each step]
                 onBeforeStep → (step executes) → onAfterStep
            onAfterScenario
onAfterAll
```

**Priority:** When multiple hooks are registered, they execute in descending priority order (highest first). Default priority is `0`.

---

## Reporters

Reporters observe the same lifecycle events as hooks and are used to collect and output test results.

### SummaryReporter

Prints a concise summary to the terminal after the test run:

```
3 scenarios (2 passed, 1 failed)
Elapsed: 00:01:23.456
```

```dart
reporters: [SummaryReporter()],
```

### JsonReporter

Generates a Cucumber-compatible JSON report file. This file can be consumed by the [`cucumber-html-reporter`](https://www.npmjs.com/package/cucumber-html-reporter) npm package to produce rich HTML reports.

```dart
reporters: [JsonReporter(path: 'reports/test_report.json')],
```

The JSON file is written to the host machine via the [Bridge Server](#bridge-server). If you are not using the bridge, the file will not be saved.

**Generating an HTML report (requires Node.js):**

```bash
npm install cucumber-html-reporter --save-dev
```

```js
// generate_report.js
const reporter = require('cucumber-html-reporter');
reporter.generate({
  theme: 'bootstrap',
  jsonFile: 'reports/test_report.json',
  output: 'reports/cucumber_report.html',
  reportSuiteAsScenarios: true,
});
```

```bash
node generate_report.js
```

### Custom Reporters

Extend `IntegrationReporter` to build your own output format:

```dart
import 'package:flutter_bdd_suite/reporters/integration_reporter.dart';
import 'package:flutter_bdd_suite/models/models.dart';
import 'package:flutter_bdd_suite/steps/step_result.dart';
import 'package:flutter_bdd_suite/world/widget_tester_world.dart';

class MyReporter extends IntegrationReporter {
  @override
  String get path => 'my_report.txt';

  @override
  Future<void> onBeforeScenario(ScenarioInfo scenario) async {
    print('▶ ${scenario.scenarioName}');
  }

  @override
  Future<void> onAfterStep(StepResult result, StepContext ctx) async {
    final icon = result is StepSuccess ? '✓' : result is StepFailure ? '✗' : '○';
    print('  $icon ${result.stepText}');
  }

  @override
  Map<String, dynamic> toJson() => {};
}
```

---

## Bridge Server

Flutter integration tests execute **inside the tested app process**, which runs on the target platform — an Android device or emulator, an iOS simulator, a desktop window, or a browser tab. In all of these environments the test code cannot directly access the host machine's file system, run host-level processes, or talk to services that are bound to the host's `127.0.0.1`.

The Bridge solves this by running a lightweight HTTP server **on the host machine** (your development computer or CI agent) while the tests run. Device-side code calls it using the helper functions `bridgeGet` and `bridgePostJson`. Because the server is a plain Dart `HttpServer`, its handlers can use any Dart `dart:io` API — read and write files, spawn processes, connect to local databases, call external REST APIs, or anything else.

This works uniformly across **all supported platforms**: Android, iOS, macOS, Linux, Windows, and Web. The bridge client automatically resolves the correct host address for each platform (see below).

### Common Use Cases

| Goal | How |
|---|---|
| Save a JSON report to the host disk (including from Web) | `JsonReporter` calls `POST /save-report` automatically. |
| Reset or seed a database before a scenario | Call `bridgePostJson('/db/reset')` from a `onBeforeScenario` hook. |
| Read a fixture file from the host file system | Register a `GET /fixture` endpoint that reads the file and returns its content. |
| Trigger a host-side script or CI action | Register a `POST /run-script` endpoint that uses `dart:io` `Process.run`. |
| Call a service bound to host `127.0.0.1` | Forward the call through the bridge — the bridge handler reaches `127.0.0.1` from the host. |

### Host-Side Server

The bridge is started automatically by `cli` unless `--no-bridge` is specified. Register custom endpoints in a bridge setup file:

```dart
// integration_test/bridge_setup.dart
import 'dart:io';
import 'package:flutter_bdd_suite/server/integration_test_server.dart';
import 'package:flutter_bdd_suite/models/endpoint_registration_model.dart';

void registerEndpoints(IntegrationTestServer server) {
  // Example: return host directory listing
  server.registerEndpoint(EndpointRegistration(
    method: 'GET',
    path: '/hello',
    handler: (request) async {
      final dir = Directory.current;
      request.response
        ..statusCode = 200
        ..write('Host cwd: ${dir.path}')
        ..close();
    },
  ));

  // Example: reset a local SQLite database before a test run
  server.registerEndpoint(EndpointRegistration(
    method: 'POST',
    path: '/db/reset',
    handler: (request) async {
      await File('test.db').writeAsBytes([]);
      request.response
        ..statusCode = 200
        ..close();
    },
  ));
}
```

Then pass the file with `--bridge-setup`:

```bash
dart run flutter_bdd_suite:cli \
  --config test_config.dart \
  --bridge-setup integration_test/bridge_setup.dart
```

### Drive/Web Server Setup Checklist

When running with `--mode drive` (especially `-d chrome`), use this checklist to avoid missing bridge logs or report-save failures:

1. Keep the bridge enabled. Do not pass `--no-bridge`.
2. Make sure the bridge port is free before running. Default is `9876`.
3. If the CLI prints a bridge warning (for example, port already in use), mirrored reporter logs and host-side endpoints will not be available for that run.
4. For multiline shell commands, keep passthrough args after `--` on the same command using `\` line continuation.

Example:

```bash
dart run flutter_bdd_suite:cli \
  --mode drive \
  --config test_config.dart \
  -- --driver=test_driver/integration_test.dart \
     --target=integration_test/app_test.dart \
     -d chrome
```

#### macOS App Sandbox Requirement

If your test app runs with macOS sandbox entitlements, the app must be allowed to make outbound network calls to reach the local bridge (`http://127.0.0.1:9876`).

In `macos/Runner/DebugProfile.entitlements` (and optionally `Release.entitlements`), include:

```xml
<key>com.apple.security.network.client</key>
<true/>
```

Without this entitlement, bridge calls can fail with errors similar to `SocketException: Operation not permitted`.

#### Why `flutter drive` Logs Can Differ from `flutter test`

For web drive runs, Flutter tooling may not forward all app-side stdout the same way as `flutter test`. This can make hook/reporter logs appear incomplete even when hooks ran successfully.

To improve visibility, `flutter_bdd_suite` mirrors runtime logs through the bridge when the bridge is active.

### Device-Side HTTP Client

Create thin wrapper functions in `integration_test/integration_endpoints/` to call your bridge endpoints from step definitions or hooks:

```dart
// integration_test/integration_endpoints/endpoints.dart
import 'package:flutter_bdd_suite/server/bridge_client.dart';
import 'package:flutter_bdd_suite/models/integration_server_result_model.dart';

Future<IntegrationServerResult> sayHello() => bridgeGet('/hello');

Future<IntegrationServerResult> resetDatabase() => bridgePostJson('/db/reset');
```

Use them in a hook:

```dart
class SetupHook extends IntegrationHook {
  @override
  Future<void> onBeforeScenario(ScenarioInfo scenario) async {
    await resetDatabase();
  }
}
```

Or in a step definition:

```dart
StepDefinitionGeneric theDbIsReset() => step(
  'the database has been reset',
  (StepContext ctx) async {
    final result = await resetDatabase();
    expect(result.success, isTrue);
  },
);
```

### Host Address Resolution

The bridge client automatically picks the right address so you never need to hard-code it:

| Platform | Default host |
|---|---|
| Android emulator | `10.0.2.2` (routes to host `127.0.0.1`) |
| Android physical device | Set `FGP_BRIDGE_HOST` env var or `--bridge-host` to the host's network IP. |
| iOS simulator | `127.0.0.1` |
| macOS / Linux / Windows desktop | `127.0.0.1` |
| Web (Chrome) | `127.0.0.1` |

Override with the `FGP_BRIDGE_HOST` / `FGP_BRIDGE_PORT` environment variables, or the `--bridge-host` / `--bridge-port` CLI flags.

### `IntegrationServerResult`

All bridge calls return an `IntegrationServerResult`:

| Property | Type | Description |
|---|---|---|
| `success` | `bool` | Whether the request succeeded (HTTP 2xx). |
| `statusCode` | `int` | HTTP status code. |
| `message` | `String?` | Response body text (if any). |

---

## Tag Filtering

Use the `--tags` CLI flag with a boolean tag expression to run only matching scenarios:

| Expression | Meaning |
|---|---|
| `@smoke` | Scenarios tagged `@smoke`. |
| `not @wip` | Scenarios **not** tagged `@wip`. |
| `@smoke and @auth` | Scenarios tagged with **both** `@smoke` and `@auth`. |
| `@smoke or @regression` | Scenarios tagged with `@smoke` **or** `@regression`. |
| `(@smoke or @auth) and not @wip` | Compound expressions with parentheses. |

```bash
# Run only smoke tests that are not WIP
dart run flutter_bdd_suite:cli \
  --config test_config.dart \
  --tags "(@smoke or @auth) and not @wip"
```

Scenarios that do not match the expression are excluded from the generated test files and are never executed.

---

## Additional Information

- For an introduction to BDD and Gherkin, visit the [Cucumber Documentation](https://cucumber.io/docs/).
- For details on Flutter integration testing, see the [Flutter Integration Test](https://docs.flutter.dev/testing/integration-tests) guide.
- Found a bug or have a feature request? Open an issue on the package's repository.
