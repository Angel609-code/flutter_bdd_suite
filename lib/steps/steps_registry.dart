import 'package:flutter_bdd_suite/steps/when_fill_field_step.dart';
import 'package:flutter_bdd_suite/utils/step_definition_generic.dart';
import 'package:flutter_bdd_suite/utils/steps_keywords.dart';
import 'package:flutter_bdd_suite/world/widget_tester_world.dart';

/// Type definition for resolved step functions.
///
/// Receive the active [world]. Any attached data (table or doc-string) can be
/// accessed via [world.multilineArg] or the convenience shortcuts [world.table]
/// and [world.docString].
typedef StepFunction = Future<void> Function(WidgetTesterWorld world);

/// A per-execution registry that maps Gherkin step patterns to their Dart
/// implementations.
///
/// Create one [StepsRegistry] instance per [IntegrationTestHelper] execution.
/// Custom steps are supplied at construction time via the `extraSteps`
/// parameter, which is populated from [IntegrationTestConfig.steps].
/// This fully isolates step state between test suites running in the same
/// process.
///
/// **Migration note:** The old static API (`StepsRegistry.addAll`,
/// `StepsRegistry.resetToDefaults`, `StepsRegistry.getStep`) has been removed.
/// Custom steps should be declared in [IntegrationTestConfig.steps]; the
/// helper creates the registry automatically.
///
/// Example:
/// ```dart
/// final registry = StepsRegistry(extraSteps: config.steps);
/// final fn = registry.getStep('I fill the "email" field with "bob@example.com"');
/// if (fn != null) await fn(world);
/// ```
class StepsRegistry {
  /// All built-in steps shipped with the library.
  ///
  /// A read-only list; never mutated at runtime. Custom steps are merged at
  /// construction time into [_steps].
  static final List<StepDefinitionGeneric> defaultSteps = [
    whenFillFieldStep(),
  ];

  /// The active step definitions for this registry instance.
  ///
  /// Initialized as `[...defaultSteps, ...extraSteps]` and never mutated
  /// after construction.
  final List<StepDefinitionGeneric> _steps;

  /// Creates a registry seeded with [defaultSteps] plus any [extraSteps].
  ///
  /// Steps are matched in declaration order: [defaultSteps] are checked first,
  /// then [extraSteps]. An [StateError] is thrown at lookup time if more than
  /// one step matches (ambiguous match).
  StepsRegistry({List<StepDefinitionGeneric> extraSteps = const []})
      : _steps = [...defaultSteps, ...extraSteps];

  /// Looks up a matching step by [stepText], or returns `null` if none found.
  ///
  /// Throws a [StateError] if more than one registered step definition
  /// matches [stepText] (ambiguous match).
  StepFunction? getStep(String stepText) {
    final cleanedStepText = cleanStepText(stepText);

    final matches = _steps
        .where((stepDef) => stepDef.matches(cleanedStepText))
        .toList();

    if (matches.length > 1) {
      final patterns = matches.map((s) => s.pattern.pattern).join('\n  ');
      throw StateError(
        'Ambiguous match: ${matches.length} step definitions matched "$cleanedStepText":\n  $patterns',
      );
    }

    if (matches.isEmpty) return null;

    final stepDef = matches.first;
    return (world) => stepDef.run(cleanedStepText, world);
  }
}
