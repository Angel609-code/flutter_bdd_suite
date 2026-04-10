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

  /// Memoization cache: maps raw step text to its resolved [StepFunction].
  ///
  /// The same step text (e.g. "Given the app is launched") may appear in many
  /// scenarios. By caching the result of the first lookup the framework avoids
  /// re-running every regex match on every scenario execution.
  ///
  /// `null` values are cached too — they mean "no matching step definition was
  /// found" — so an unimplemented step is not re-scanned on every scenario.
  final Map<String, StepFunction?> _cache = {};

  /// Creates a registry seeded with [defaultSteps] plus any [extraSteps].
  ///
  /// Steps are matched in declaration order: [defaultSteps] are checked first,
  /// then [extraSteps]. An [StateError] is thrown at lookup time if more than
  /// one step matches (ambiguous match).
  StepsRegistry({List<StepDefinitionGeneric> extraSteps = const []})
      : _steps = [...defaultSteps, ...extraSteps];

  /// Looks up a matching step by [stepText], or returns `null` if none found.
  ///
  /// Results are memoised: the first call for a given [stepText] scans all
  /// registered definitions and caches the result; subsequent calls return the
  /// cached value immediately.
  ///
  /// Throws a [StateError] if more than one registered step definition
  /// matches [stepText] (ambiguous match).
  StepFunction? getStep(String stepText) {
    if (_cache.containsKey(stepText)) return _cache[stepText];
    final fn = _resolve(stepText);
    _cache[stepText] = fn;
    return fn;
  }

  /// Scans [_steps] for a definition that matches [stepText].
  ///
  /// Uses an early-exit loop so that the scan stops as soon as a second match
  /// is detected (the ambiguous case). In the common single-match case the
  /// loop reads only as far as the matching entry — no list is allocated.
  StepFunction? _resolve(String stepText) {
    final cleanedStepText = cleanStepText(stepText);

    StepDefinitionGeneric? match;
    for (final stepDef in _steps) {
      if (stepDef.matches(cleanedStepText)) {
        if (match != null) {
          // Second match found — collect all for a descriptive error message.
          final allMatches =
              _steps.where((s) => s.matches(cleanedStepText)).toList();
          final patterns =
              allMatches.map((s) => s.pattern.pattern).join('\n  ');
          throw StateError(
            'Ambiguous match: ${allMatches.length} step definitions matched '
            '"$cleanedStepText":\n  $patterns',
          );
        }
        match = stepDef;
      }
    }

    if (match == null) return null;
    return (world) => match!.run(cleanedStepText, world);
  }
}
