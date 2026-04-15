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
  - [Expression vs RegExp Steps](#expression-vs-regexp-steps)
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
- **Native Integration Test:** Built on Flutter's `integration_test` package.
- **Automatic Code Generation:** Converts `.feature` files into executable Dart integration test files with a single CLI command.
- **Rich Gherkin Parsing:** Full support for Scenario Outlines, Background, Rules, data tables, doc strings, tags, etc.
- **Flexible Step Definitions:** Define steps with pure Cucumber Expressions (`step()`) or powerful Regular Expressions (`stepRegExp()`). Data tables and doc-strings are naturally accessible via the step context.
- **Lifecycle Hooks:** Before/after hooks at the All, Feature, Scenario, and Step levels with priority-based execution. Compose your own by extending `IntegrationHook`.
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
    When I fill the username field with "alice"
    And I fill the password field with "secret"
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
    When I fill the username field with "<username>"
    And I fill the password field with "<password>"
    And I tap the login button
    Then I should see "<result>"

    Examples:
      | username | password | result        |
      | alice    | secret   | home screen   |
      | bob      | wrong    | error message |
      |          |          | error message |
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

In your step definition, access the table via `ctx.table()` (see [Working with Tables in Steps](#working-with-tables-in-steps)).

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
import 'package:flutter_bdd_suite/flutter_bdd_suite.dart';
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

  // Custom step definitions
  steps: [
    myCustomStep(),
    anotherStep(),
  ],

  // Lifecycle hooks
  hooks: [
    MyHook(),
  ],

  // Controls the visual representation of reports
  presentation: ReportPresentation(
    showStepPaths: true,
    showStackTraces: true,
  ),

  // Result reporters
  reporters: [
    JsonReporter(path: 'report/report.json'),
  ],
);
```

| Property | Type | Description |
|---|---|---|
| `setUp` | `Future<void> Function(WidgetTester)?` | Optional callback run once per scenario before Background and Scenario steps. Use this to reset state and optionally mount the app. |
| `onBindingInitialized` | `Future<void> Function(IntegrationTestWidgetsFlutterBinding)?` | Optional setup hook run once after binding initialization. |
| `steps` | `List<StepDefinitionGeneric>` | Custom step definitions to add to the registry. |
| `hooks` | `List<IntegrationHook>` | Lifecycle hooks executed around tests. |
| `presentation` | `ReportPresentation` | Controls output formatting (colors, paths, stack traces, etc.). |
| `reporters` | `List<IntegrationReporter>` | List of additional result reporters. |
| `useDefaultReporter` | `bool` | Whether to enable the standard Cucumber-like reporter. Defaults to `true`. |

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
  return step('the application is launched', (ctx) async {
    await ctx.tester.pumpWidget(const MyApp());
    await ctx.tester.pumpAndSettle();
  });
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
3. For multiline shell commands, keep passthrough args after `--` on the same command using `\` line continuation.

### Test Mode (Mobile & Desktop)

This is the default mode. It uses `flutter test`.

```bash
dart run flutter_bdd_suite:cli \
  --config test_config.dart \
  -- \
  -d linux
```

### Drive Mode (Web)

Use this when running tests on the web. It uses `flutter drive`.

```bash
dart run flutter_bdd_suite:cli \
  --mode drive \
  --config test_config.dart \
  -- \
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
| `--no-colors` | `false` | Suppress ANSI color codes in console output. |
| `--show-paths` | `false` | Include feature file paths and line numbers in output. |
| `--show-stack-traces` | `false` | Print full stack traces for failed steps. |
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
```

---

## Code Generation

The CLI orchestrator automatically regenerates test files before each execution. If you prefer to manually generate them without running tests (e.g. in a pre-commit hook), use the `--generate-only` flag.

```bash
dart run flutter_bdd_suite:cli --config test_config.dart --generate-only
```

Generated files are output into the `integration_test/generated/` directory.

> **Note:** The generated directory should be ignored in version control (`.gitignore`) as well the `all_integration_tests.dart`.

---

## Coverage

To generate test coverage, you must use `--mode test` (the default). Coverage is generated by the underlying `flutter test` command.

1. Pass the `--coverage` flag after the `--` separator.
2. Provide the `lcov.info` generated path to `genhtml` to build the report.

```bash
# Run tests and collect coverage
dart run flutter_bdd_suite:cli \
  --config test_config.dart \
  -- \
  --coverage

# Generate HTML report from lcov.info
genhtml coverage/lcov.info -o coverage/html
```

> **Requirements:** The `genhtml` command is part of the `lcov` package, which must be installed on your system.

| Platform | Install Command |
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

### Custom Steps

Define custom steps using the `step()` and `stepRegExp()` functions. Each step receives a `StepContext` (`ctx`), providing access to `ctx.tester`, `ctx.args`, and multiline strings/tables.

```dart
import 'package:flutter_bdd_suite/flutter_bdd_suite.dart';

// Plain step with no placeholders
StepDefinitionGeneric theAppIsLaunched() {
  return step('the application is launched', (ctx) async {
    await ctx.tester.pumpWidget(const MyApp());
    await ctx.tester.pumpAndSettle();
  });
}

// Step with Cucumber Expression placeholders
StepDefinitionGeneric iFillField() {
  return step('I fill the {string} field with {string}', (ctx) async {
    // Safely extract the arguments with type safety
    final (field, value) = ctx.args.two<String, String>();

    await ctx.tester.enterText(find.byKey(Key(field)), value);
    await ctx.tester.pumpAndSettle();
  });
}

// Manual regex capture — use a regex group directly in the pattern
StepDefinitionGeneric waitSeconds() {
  return stepRegExp(
    RegExp(r'I wait (\d+) seconds?'),
    (ctx) async {
      final (seconds) = ctx.args.one<String>();
      await Future.delayed(Duration(seconds: int.parse(seconds)));
    }
  );
}
```

Register your steps in the config:

```dart
final config = IntegrationTestConfig(
  setUp: ...,
  steps: [
    theAppIsLaunched(),
    iFillField(),
    waitSeconds(),
  ],
);
```

### Expression vs RegExp Steps

This framework enforces a strict separation between simple Cucumber Expressions and powerful Regular Expressions. This ensures predictability and prevents bugs caused by mixing the two.

#### `step()` (Cucumber Expressions)
Use `step()` for the vast majority of your definitions. It accepts plain text and `{}` placeholders.
**Important:** Do not use raw regex features (like `(?:...)`, `|`, `^`, `$`) inside `step()`. The framework will throw a helpful runtime error if it detects them.

```dart
// GOOD: Plain text
step('the application is launched', (ctx) async { ... });

// GOOD: Placeholders
step('I fill the {string} field with {string}', (ctx) async {
  final (field, value) = ctx.args.two<String, String>();
  // ...
});
```

#### `stepRegExp()` (Regular Expressions)
Use `stepRegExp()` *only* when you need advanced regex logic like alternations, optional words, or specific lookarounds.

```dart
// GOOD: Using non-capturing groups (?:) to accept multiple phrasings
// without polluting the arguments list.
stepRegExp(
  RegExp(r'I (?:enter|fill) the (.+?)(?: field with)? "(.+?)"'),
  (ctx) async {
    final (field, value) = ctx.args.two<String, String>();
    // ...
  }
);
```

### Regex steps: capturing vs non-capturing groups

When using `stepRegExp()`, it is critical to understand how Regex groupings translate into `StepArgs`:

1. **Only capturing groups `(...)` produce an argument.**
2. **Non-capturing groups `(?:...)` are ignored** by the argument list. This is extremely useful for alternations (e.g. `(?:enter|fill)`).
3. **Optional captures yield `null`.** If a capturing group is bypassed, its corresponding argument will be `null` (meaning you must type it as `String?`).

#### Multi-state steps (Best Practice)
If a single step handles multiple states (e.g., "is visible" vs "is not present"), **capture the entire state block** instead of hiding the words in a non-capturing group.

```dart
stepRegExp(
  RegExp(r'(.+?) element(?:s)? (?:is|are) (visible|present|"(.+?)")'),
  (ctx) async {
    // The regex has exactly THREE capturing groups: `(.+?)`, the entire state, and the optional quoted string.
    final (type, stateRaw, quoted) = ctx.args.three<String, String, String?>();

    final key = resolveKey(type);

    // If the user used quotes (e.g., "hidden"), `quoted` will contain "hidden".
    // Otherwise, `stateRaw` will contain the exact word they typed (e.g., "visible" or "present").
    final state = quoted ?? stateRaw;

    switch (state) {
      case 'visible':
      case 'present':
        expect(find.byKey(Key(key)), findsOneWidget);
        break;
      case 'not visible':
      case 'hidden':
        expect(find.byKey(Key(key)), findsNothing);
        break;
    }
  },
);
```

If you request `ctx.args.four()` for this step, the framework will throw a helpful runtime error explaining the mismatch between your capture groups and your request.

### Custom Parameter Types

You can register custom parameter models to be automatically parsed from your step text:

```dart
import 'package:flutter_bdd_suite/flutter_bdd_suite.dart';

// In your setup file:
ParameterTypes.register<Color>(
  'color',
  r'(red|blue|green)',
  (val) => Color.parse(val),
);
```

Then use it in a step:

```dart
step('the background should be {color}', (ctx) async {
    final (color) = ctx.args.one<Color>();
});
```

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

### Working with Tables in Steps

Data tables are **first-class properties** on the `Step` model — they are never embedded in the step text string. When the runner matches a step, it attaches the table or doc-string to the `WidgetTesterWorld` context object.

For `step()` and `stepRegExp()` definitions, access multiline arguments from `StepContext` using:

- `ctx.table()`
- `ctx.docString()`

Both methods return the parsed value when present, and throw a `StateError` when missing. This keeps step code explicit and fail-fast.

```dart
// Step with no captures, but reads an attached table
StepDefinitionGeneric givenEmployeesExist() => step(
  'the following employees exist',
  (ctx) async {
    final table = ctx.table();
    for (final row in table.asMap()) {
      logLine('Name: ${row['name']}, Role: ${row['role']}');
    }
  },
);

// Step with captures AND doc-string content
StepDefinitionGeneric fillFieldWithDocString() => stepRegExp(
  RegExp(r'^I fill the (.+?) field with$'),
  (ctx) async {
    final (field,) = ctx.args.one<String>();
    final content = ctx.docString();
    logLine('Fill $field with: $content');
  },
);
```

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

- `world.tester` — the Flutter `WidgetTester` for interacting with the widget tree.
- `world.binding` — the `IntegrationTestWidgetsFlutterBinding`.
- `world.setAttachment<T>(key, value)` / `world.getAttachment<T>(key)` — share state between steps within the same scenario.

**Example — sharing state between steps:**

```dart
// Step 1: store a value
StepDefinitionGeneric iRememberTheText() => step(
  'I remember the text {string}',
  (ctx) async {
    final (text,) = ctx.args.one<String>();
    ctx.world.setAttachment('remembered_text', text);
  },
);

// Step 2: retrieve the stored value
StepDefinitionGeneric iVerifyTheText() => step(
  'I verify the remembered text',
  (ctx) async {
    final text = ctx.world.getAttachment<String>('remembered_text');
    expect(find.text(text!), findsOneWidget);
  },
);
```

---

## Hooks

Hooks are blocks of code that run at various points in the BDD execution cycle. They are typically used to set up and tear down environments, seed databases, or manage Flutter state before and after features or scenarios.

By extending `IntegrationHook`, you can implement methods that map perfectly to the Cucumber lifecycle, fully adapted for Dart and Flutter Integration Tests.

### Execution Order (The Onion Model)
Hooks are composable and define an execution `priority` (default is 0). `onBefore*` hooks execute in **descending** order (highest priority first). `onAfter*` hooks execute in **reverse** order (lowest priority first). This guarantees symmetric teardown (if Hook A sets up a database, and Hook B populates it, Hook B cleans up before Hook A destroys the database).

You can declare all your hooks in a single class or split them into multiple classes.

```dart
import 'package:flutter_bdd_suite/flutter_bdd_suite.dart';

class MyCustomHook extends IntegrationHook {
  @override
  int get priority => 10; // higher priority runs first

  // --------------------------------------------------------------------------
  // Global Hooks: Run once for the entire test suite.
  // --------------------------------------------------------------------------

  /// Runs once before any scenario is run
  @override
  Future<void> onBeforeAll() async {}

  /// Runs once after all scenarios have been executed
  @override
  Future<void> onAfterAll() async {}

  // --------------------------------------------------------------------------
  // Feature Hooks: Run before and after an entire feature file.
  // --------------------------------------------------------------------------

  /// Access feature.featureName, feature.tags, etc.
  @override
  Future<void> onBeforeFeature(FeatureInfo feature) async {}

  /// Clean up resources used by the feature
  @override
  Future<void> onAfterFeature(FeatureInfo feature) async {}

  // --------------------------------------------------------------------------
  // Scenario Hooks: Run for every scenario.
  // --------------------------------------------------------------------------

  /// Runs before the first step of each scenario (including Background steps).
  /// Use this for low-level logic (e.g. seeding a database).
  /// NOTE: Avoid using this for UI setup; use Background steps instead for better readability.
  @override
  Future<void> onBeforeScenario(ScenarioInfo scenario) async {}

  /// Runs after the last step of each scenario, even if failed or skipped.
  @override
  Future<void> onAfterScenario(ScenarioResult result) async {
    // Clean up scenario resources. You can inspect the final status:
    if (result.status == ScenarioExecutionStatus.failed) {
      logLine('Scenario failed: ${result.scenarioName}');
    }
  }

  // --------------------------------------------------------------------------
  // Step Hooks: Wrap individual steps.
  // --------------------------------------------------------------------------

  /// Executed right before the step function is invoked.
  /// Not called for steps that are skipped because a prior step failed.
  @override
  Future<void> onBeforeStep(BeforeStepContext context) async {
    logLine('About to run: ${context.stepText}');
  }

  /// Executed right after the step function is invoked.
  /// Not called for skipped steps (user hooks); reporters still receive it.
  @override
  Future<void> onAfterStep(AfterStepContext context) async {
    final result = context.result;
    final world = context.world;
    final scenario = context.scenario;

    if (result is StepFailure) {
      final tester = world.testerOrNull;
      if (tester != null) {
        logLine(
          'Taking screenshot for failed step in '
          '${scenario?.scenarioName ?? 'background'}: ${result.stepText}',
        );
      }
    }
  }
}
```

For step-level callbacks, the data is wrapped in context objects instead of being passed as separate positional parameters:

- `BeforeStepContext` exposes `stepText`, `world`, and `scenario`.
- `AfterStepContext` exposes `result`, `world`, and `scenario`.
- `scenario` can be `null` while background steps are running.

### Conditional Hooks
Hooks can be conditionally selected based on Gherkin tags using a tag expression. Provide an expression overriding `tagExpression` to run a hook only when those tags are active on a feature or scenario.

```dart
class WebOnlyHook extends IntegrationHook {
  // Only execute this hook if the scenario or feature has the @web tag
  // and does NOT have the @headless tag.
  @override
  String? get tagExpression => '@web and not @headless';

  @override
  Future<void> onBeforeScenario(ScenarioInfo scenario) async {
    // Configure web-specific driver settings
  }
}
```

**Lifecycle order:**

```
onBeforeAll
  └─ [for each feature]
       onBeforeFeature
       └─ [for each scenario]
            onBeforeScenario
            └─ [for each step]
                 onBeforeStep → (step executes) → onAfterStep
                 (skipped steps bypass onBeforeStep and onAfterStep for hooks)
            onAfterScenario
       onAfterFeature
onAfterAll
```

**Priority:** When multiple hooks are registered, they execute in descending priority order (highest first). Default priority is `0`.

---

## Reporters

Reporters observe the same lifecycle events as hooks and are used to collect and output test results.

By default, `flutter_bdd_suite` uses a built-in **CucumberReporter** that prints standard Gherkin-style output to your terminal. You can customize its behavior using **Presentation Settings**.

### Presentation Settings

Use the `ReportPresentation` model in your config (or CLI flags) to control how results are displayed.

```dart
final config = IntegrationTestConfig(
  presentation: ReportPresentation(
    useColors: true,          // Default: true
    showStepPaths: false,     // Default: false
    showDebugLogs: false,     // Default: false
    showStackTraces: false,   // Default: false
  ),
);
```

### CLI Overrides

All presentation settings can be overridden at runtime via CLI flags:

- `--no-colors`
- `--show-paths`
- `--show-stack-traces`

### SummaryReporter

Prints a concise one-line summary after the run. Note that the default `CucumberReporter` now includes its own summary by default.

```dart
reporters: [SummaryReporter()],
```

### JsonReporter

Generates a Cucumber-compatible JSON report file. This file can be consumed by the [`cucumber-html-reporter`](https://www.npmjs.com/package/cucumber-html-reporter) npm package to produce rich HTML reports.

```dart
reporters: [JsonReporter(path: 'report/report.json')],
```

The JSON file is written to the host machine via the [Bridge Server](#bridge-server). If you are not using the bridge, the file will not be saved.

**Generating an HTML report (requires Node.js):**

```bash
npm install cucumber-html-reporter --save-dev
```

```js
// generate_report.js
var reporter = require('cucumber-html-reporter');

var options = {
        theme: 'bootstrap',
        jsonFile: 'report.json',
        output: 'report.html',
        reportSuiteAsScenarios: true,
        scenarioTimestamp: true,
        launchReport: true,
        metadata: {
            "App Version":"0.3.2",
            "Test Environment": "STAGING",
            "Browser": "Chrome  54.0.2840.98",
            "Platform": "Windows 10",
            "Parallel": "Scenarios",
            "Executed": "Remote"
        },
        failedSummaryReport: true,
    };

    reporter.generate(options);
    

    //more info on `metadata` is available in `options` section below.

    //to generate consodilated report from multi-cucumber JSON files, please use `jsonDir` option instead of `jsonFile`. More info is available in `options` section below.
```

```bash
node generate_report.js
```

### Custom Reporters

Extend `IntegrationReporter` to build your own output format. Reporter lifecycle methods use the same callback signatures as hooks.

Unlike hooks, reporters are for observation and output only. In practice they should stay unconditional so they can capture the full run. They also receive `onAfterStep(AfterStepContext context)` for skipped steps, which allows them to render complete scenario output even when execution short-circuits.

If your reporter writes to disk, pass the output path to `super(path: ...)`:

```dart
import 'package:flutter_bdd_suite/flutter_bdd_suite.dart';

class MyReporter extends IntegrationReporter {
  MyReporter() : super(path: 'my_report.txt');

  @override
  Future<void> onBeforeScenario(ScenarioInfo scenario) async {
    logLine('▶ ${scenario.scenarioName}');
  }

  @override
  Future<void> onAfterStep(AfterStepContext context) async {
    final result = context.result;
    final icon = result is StepSuccess ? '✓' : result is StepFailure ? '✗' : '○';
    logLine('  $icon ${result.stepText}');
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
import 'package:flutter_bdd_suite/flutter_bdd_bridge.dart';

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

### Device-Side HTTP Client

Create thin wrapper functions in `integration_test/integration_endpoints/` to call your bridge endpoints from step definitions or hooks:

```dart
// integration_test/integration_endpoints/endpoints.dart
import 'package:flutter_bdd_suite/flutter_bdd_suite.dart';

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
StepDefinitionGeneric theDbIsReset() {
  return step(
    'the database has been reset',
    (ctx) async {
      final result = await resetDatabase();
      expect(result.success, isTrue);
    },
  );
}
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

## Step Results

Each executed step in a scenario resolves to one of the standard Cucumber step results:

* **Success**: The step definition matched and executed without error.
* **Skipped**: The step was not executed because a prior step failed, became pending, or was undefined.
* **Undefined**: No matching step definition was found in the `StepsRegistry`. This will fail the scenario.
* **Pending**: The step explicitly threw a `PendingStepException`. Indicates that the automation is explicitly marked as work-in-progress. This will fail the scenario.
* **Failure**: The step definition matched but execution threw an error or an assertion failed. This will fail the scenario.
* **Ambiguous**: More than one step definition matched the step text. This throws an `AmbiguousStepException` internally and yields this result. This will fail the scenario.

### Pending Steps

If you want to explicitly mark a step as pending (work-in-progress) without failing the execution abruptly via a crash, throw a `PendingStepException` in your step definition:

```dart
import 'package:flutter_bdd_suite/flutter_bdd_suite.dart';

StepDefinitionGeneric myPendingStep() {
  return step(
    'I am doing some work in progress',
    (ctx) async {
      throw PendingStepException('Automation not ready yet');
    },
  );
}
```

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
