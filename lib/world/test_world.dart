import 'package:flutter_bdd_suite/models/step_multiline_arg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Public API: this is all that test‐writers see.
///
/// It holds exactly:
///   • a reference to the current [WidgetTester] and [IntegrationTestWidgetsFlutterBinding]
///   • a key/value store for any custom data ([setAttachment], [getAttachment])
///   • the optional [multilineArg] (data table or doc-string) for the current step
///
/// No lifecycle hooks (beforeScenario, beforeStep, etc.) live here.
/// Those belong in your `IntegrationHook` classes.
abstract class TestWorld {
  /// Internal setter to inject the [WidgetTester]. Not for public use.
  Future<void> setTester(WidgetTester tester);

  /// Internal setter to inject the [IntegrationTestWidgetsFlutterBinding].
  /// Not for public use.
  Future<void> setBinding(IntegrationTestWidgetsFlutterBinding binding);

  /// The [WidgetTester] instance used to pump frames, find widgets, and
  /// simulate user interactions.
  ///
  /// Throws a [StateError] if accessed before the scenario setup has
  /// successfully initialized the tester. Use [testerOrNull] in hooks
  /// if you are unsure of the initialization state.
  WidgetTester get tester;

  /// Returns the current [WidgetTester], or `null` if it has not been
  /// initialized yet. Use this in hooks (like `onBeforeAll`) to safely check
  /// for tester availability.
  WidgetTester? get testerOrNull;

  /// The integration test binding.
  IntegrationTestWidgetsFlutterBinding get binding;

  /// The optional [StepMultilineArg] (data table or doc-string) attached to the
  /// currently executing step.
  ///
  /// This is automatically populated by the framework before a step executes
  /// and cleared after.
  StepMultilineArg? get multilineArg;

  /// Internal setter to inject the multiline argument. Not for public use.
  void setMultilineArg(StepMultilineArg? arg);

  /// A simple place to stash any shared data (keyed by String) during the run.
  void setAttachment<T>(String key, T value);

  /// Retrieve a previously‐stored attachment (or null).
  T? getAttachment<T>(String key);
}
