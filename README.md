# flutter_bdd_suite

`flutter_bdd_suite` is a comprehensive BDD (Behavior-Driven Development) testing and parsing package for Flutter. It helps you write clear, human-readable tests that describe the behavior of your application, ensuring that your code does exactly what it is supposed to do.

Whether you're a junior developer getting started with testing or a seasoned engineer looking to improve collaboration, writing BDD tests can bridge the gap between developers, QA, and non-technical stakeholders.

This package is built natively on top of Flutter's `integration_test` framework, providing direct access to the Flutter widget tree and lifecycle, significantly improving upon older `flutter_driver` approaches.

---

## Table of Contents

- [Features](#features)
- [Getting Started](#getting-started)
- [BDD & Gherkin Syntax](#bdd--gherkin-syntax)
- [Usage](#usage)
  - [Test Mode (Default)](#test-mode-default)
  - [Drive Mode (For Web)](#drive-mode-for-web)
- [Coverage](#coverage)
- [Architecture & Advanced Features](#architecture--advanced-features)
  - [Test World](#test-world)
  - [Custom Steps](#custom-steps)
  - [Hooks](#hooks)
  - [Reporters](#reporters)
  - [Server Endpoint Approach (Bridge)](#server-endpoint-approach-bridge)
- [Additional Information](#additional-information)

---

## Features

- **BDD Approach:** Follows the [Cucumber BDD approach](https://cucumber.io/docs/) for defining features, scenarios, and step definitions.
- **Gherkin Syntax:** Supports the [Gherkin syntax reference](https://cucumber.io/docs/gherkin/reference). Currently, only English syntax is supported.
- **Integration Test Native:** Uses Flutter's native `integration_test` package.
- **Automatic Code Generation:** Automatically converts your `.feature` files into executable Dart integration test bindings.
- **Reporting & CI Ready:** Provides extensible reporters, including a JSON reporter compatible with external HTML reporting tools.
- **Flexible Execution:** Supports both `test` mode (for mobile/desktop) and `drive` mode (for web platforms).

---

## Getting Started

Add `flutter_bdd_suite` to your `dev_dependencies` in `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_bdd_suite: ^0.0.1
```

Create a configuration file (e.g., `test_config.dart`) to define your step definitions, hooks, and test settings.

You can then write your features in `.feature` files within your `integration_test` directory using standard Gherkin syntax.

---

## BDD & Gherkin Syntax

This package leverages the Gherkin syntax. Gherkin uses a set of special keywords to give structure and meaning to executable specifications.

*Note: Currently, the package only supports English keywords (`Feature`, `Scenario`, `Given`, `When`, `Then`, `And`, `But`). Localization features (e.g., `# language: no`) are not supported.*

Example `login.feature`:
```gherkin
Feature: Login
  Scenario: Successful login
    Given I am on the login screen
    When I enter valid credentials
    And I tap the login button
    Then I should see the home screen
```

---

## Usage

To run your tests and generate the necessary bindings, use the provided executable. The command processes your configuration, generates Dart test files from `.feature` files, and executes them.

### Test Mode (Default)

The `test` mode acts as a wrapper around the standard `flutter test` command, adapted to run generated BDD bindings. It works for most platforms (iOS, Android, macOS, Linux, Windows).

```bash
dart run flutter_bdd_suite:run_test --config test_config.dart --mode test
```
*(Note: `--mode test` is the default if omitted).*

### Drive Mode (For Web)

For web testing, Flutter integration tests currently require the older `flutter drive` approach. The `drive` mode wraps `flutter drive --driver=test_driver/integration_test.dart --target=... -d chrome`.

```bash
dart run flutter_bdd_suite:run_test --config test_config.dart --mode drive -d chrome
```

---

## Coverage

You can easily generate a coverage report for your integration tests by passing the `--coverage` flag.

**Important:** The `--coverage` flag **only** works when running in `--mode test`. The underlying `flutter drive` command does not support coverage generation.

```bash
dart run flutter_bdd_suite:run_test --config test_config.dart --mode test --coverage
```

Once the tests complete, a `coverage/lcov.info` file will be generated. You can convert this into a human-readable HTML report using `genhtml`:

```bash
genhtml coverage/lcov.info -o coverage/html
```

Open `coverage/html/index.html` in your browser to view the coverage report.

---

## Architecture & Advanced Features

The architecture of `flutter_bdd_suite` is designed to be highly extensible. Below are the key components you can leverage to build custom and advanced test suites.

### Test World

The `World` is a context object passed between steps during a scenario's execution. It holds the `WidgetTester` (giving you access to Flutter's UI tree) and allows you to share state (like variables or mock data) between steps.
The package provides `WidgetTesterWorld` out of the box.

### Custom Steps

You can easily define your own steps by registering them in your configuration. Steps map Gherkin expressions to Dart code.

```dart
// Example of creating a custom step
```

### Hooks

Hooks allow you to execute custom code at specific points in the test lifecycle (e.g., before all tests, before each scenario, after each step). Implement the `IntegrationHook` interface to set up databases, reset state, or perform cleanup.

### Reporters

The package includes different reporters to help you understand your test results. You can also build custom reporters by extending `IntegrationReporter`.

#### JsonReporter

`JsonReporter` creates a JSON file with the results of the test run. This JSON file can then be used by the [cucumber-html-reporter](https://www.npmjs.com/package/cucumber-html-reporter) npm package to create a beautiful HTML report. You pass the file path for the JSON file to be created.

*Inspiration note:* This reporter was inspired by the implementation in the `flutter_gherkin` package, but it has been specifically adapted to work natively with Flutter's `integration_test` framework rather than the deprecated `flutter_driver` approach.

```dart
final config = IntegrationTestConfig(
  reporters: [
    JsonReporter(path: 'test_report.json'),
  ],
);
```

### Server Endpoint Approach (Bridge)

The package includes an `IntegrationTestServer` approach (or "Bridge"). Because Flutter integration tests run on the device/emulator, they sometimes need to communicate with the host machine (e.g., to write report files to the host disk or interact with external host scripts).

The Bridge spins up a local server on the host machine that the device-side tests can send HTTP requests to. You can define custom endpoints on this server to perform host-side actions during the test lifecycle.

---

## Additional Information

For more information on Behavior-Driven Development and the Gherkin syntax, visit the [Cucumber Documentation](https://cucumber.io/docs/).
