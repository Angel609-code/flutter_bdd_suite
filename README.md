# flutter_bdd_suite

`flutter_bdd_suite` is a BDD (Behavior-Driven Development) testing and parsing package for Flutter. It helps you write clear, human-readable tests that describe the behavior of your application, ensuring that your code does exactly what it is supposed to do.

Whether you're a junior developer or a seasoned engineer, writing BDD tests can improve collaboration between developers, QA, and non-technical stakeholders.

## Features

- **BDD Approach:** Follows the [Cucumber BDD approach](https://cucumber.io/docs/) for defining features, scenarios, and step definitions.
- **Gherkin Syntax:** Supports the [Gherkin syntax](https://cucumber.io/docs/gherkin/reference) for writing feature files. Currently, only English is supported.
- **Integration Test Native:** Built on top of Flutter's native `integration_test` package, giving you direct access to the Flutter widget tree and lifecycle, as opposed to the older `flutter_driver` approach.
- **Automatic Code Generation:** Converts your `.feature` files into executable Dart integration tests.
- **Reporting:** Provides reporters, including a JSON reporter compatible with external HTML reporting tools.
- **Coverage Support:** Easily generate test coverage reports.

## Getting started

To get started, add `flutter_bdd_suite` to your `dev_dependencies` in `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_bdd_suite: ^0.0.1
```

Create a configuration file (e.g., `test_config.dart`) to define your step definitions, hooks, and test settings.

Then, you can write your features in `.feature` files using the Gherkin syntax.

## Usage

To run your tests and generate the necessary bindings, you can use the provided executable:

```bash
dart run flutter_bdd_suite:run_test --config test_config.dart
```

This command reads your configuration, generates Dart integration test files from your `.feature` files, and runs them.

### Coverage

You can easily generate a coverage report for your integration tests by passing the `--coverage` flag:

```bash
dart run flutter_bdd_suite:run_test --config test_config.dart --coverage
```

Once the tests complete, a `coverage/lcov.info` file will be generated. You can convert this into a human-readable HTML report using `genhtml`:

```bash
genhtml coverage/lcov.info -o coverage/html
```

You can then open `coverage/html/index.html` in your browser to view the coverage report.

### Reporters

The package includes different reporters to help you understand your test results.

#### JsonReporter

`JsonReporter` creates a JSON file with the results of the test run. This JSON file can then be used by the [cucumber-html-reporter](https://www.npmjs.com/package/cucumber-html-reporter) npm package to create a beautiful HTML report. You can pass in the file path of the json file to be created.

This reporter was inspired by the implementation in the `flutter_gherkin` package, but it has been adapted to work with Flutter's native `integration_test` framework rather than the deprecated `flutter_driver`.

```dart
// Example of adding JsonReporter in your config
final config = IntegrationTestConfig(
  reporters: [
    JsonReporter(path: 'test_report.json'),
  ],
  // ...
);
```

## Additional information

For more information on Behavior-Driven Development and the Gherkin syntax, visit the [Cucumber Documentation](https://cucumber.io/docs/).
