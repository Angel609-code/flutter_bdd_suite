/// Describes a single Cucumber parameter type.
///
/// A parameter type connects a named placeholder — e.g. `{color}` — to a
/// regex fragment that captures its value and a parser that converts the raw
/// captured string to a Dart value.
///
/// Built-in types (`{string}`, `{int}`, `{float}`, `{word}`) are pre-loaded
/// into every [ParameterTypeRegistry]. Custom types are registered either
/// globally via [ParameterTypes.register] or per-suite via
/// [ParameterTypeRegistry.new].
///
/// The [regexPart] **must** include the outer capture group, e.g.
/// `r'(red|blue|green)'`. The engine splices this fragment directly into the
/// compiled regex, so the group's content is passed to [parser].
final class ParameterType<T> {
  /// The placeholder name without braces, e.g. `'color'`.
  final String name;

  /// A regex fragment — including the outer capture group — that matches this
  /// type inside a step, e.g. `r'"(.*?)"'` for `{string}`.
  final String regexPart;

  /// Converts the raw captured string to [T].
  final T Function(String raw) parser;

  const ParameterType({
    required this.name,
    required this.regexPart,
    required this.parser,
  });
}

// ---------------------------------------------------------------------------
// ParameterTypeRegistry
// ---------------------------------------------------------------------------

/// An immutable registry of Cucumber parameter types scoped to a test suite.
///
/// Every registry starts with the four built-in types:
/// | Token      | Matches                          | Dart type  |
/// |------------|----------------------------------|------------|
/// | `{string}` | `"..."` (double-quoted text)     | `String`   |
/// | `{int}`    | optional `-` then digits         | `int`      |
/// | `{float}`  | optional `-`, digits, `.` digits | `double`   |
/// | `{word}`   | one or more non-whitespace chars | `String`   |
///
/// For project-wide custom types use [ParameterTypes.register], which adds to
/// the shared [defaultParameterTypes] registry. For per-suite isolation, create
/// a dedicated registry and pass it to [step]:
///
/// ```dart
/// final registry = ParameterTypeRegistry(additionalTypes: [
///   ParameterType(
///     name: 'color',
///     regexPart: r'(red|blue|green)',
///     parser: Color.fromName,
///   ),
/// ]);
///
/// final myStep = step('I pick {color}', action, registry: registry);
/// ```
final class ParameterTypeRegistry {
  static const List<ParameterType<dynamic>> _builtins = [
    ParameterType(
      name: 'string',
      regexPart: r'"(.*?)"',
      parser: _identity,
    ),
    ParameterType(
      name: 'int',
      regexPart: r'(-?\d+)',
      parser: int.parse,
    ),
    ParameterType(
      name: 'float',
      regexPart: r'(-?\d+(?:\.\d+)?)',
      parser: double.parse,
    ),
    ParameterType(
      name: 'word',
      regexPart: r'(\S+)',
      parser: _identity,
    ),
  ];

  static String _identity(String s) => s;

  final Map<String, ParameterType<dynamic>> _types;

  /// Creates a registry seeded with built-in types plus any [additionalTypes].
  ///
  /// [additionalTypes] are applied in order; later entries win on name
  /// conflicts, and they always override a built-in with the same name.
  ParameterTypeRegistry({
    List<ParameterType<dynamic>> additionalTypes = const [],
  }) : _types = {
         for (final t in [..._builtins, ...additionalTypes]) t.name: t,
       };

  /// Internal named constructor: creates a mutable registry for the global
  /// default instance. Only used by [defaultParameterTypes].
  ParameterTypeRegistry._mutable()
    : _types = {for (final t in _builtins) t.name: t};

  /// Library-private entry point for [ParameterTypes.register].
  ///
  /// Mutates the registry in place. Only [defaultParameterTypes] exposes this
  /// to the outside world through [ParameterTypes.register]; all other
  /// [ParameterTypeRegistry] instances are fully immutable after construction.
  void _add(ParameterType<dynamic> type) => _types[type.name] = type;

  /// Resolves [name] to its [ParameterType], or throws an [ArgumentError].
  ParameterType<dynamic> resolve(String name) {
    final t = _types[name];
    if (t == null) {
      throw ArgumentError(
        'Unknown parameter type "{$name}".\n'
        'Registered types: ${_types.keys.join(", ")}.\n'
        'To add a custom type, use ParameterTypes.register() for global scope '
        'or supply a ParameterTypeRegistry to step().',
      );
    }
    return t;
  }

  /// Whether [name] is registered in this registry.
  bool contains(String name) => _types.containsKey(name);
}

/// The shared default registry used by [step] when no explicit `registry:`
/// argument is supplied.
///
/// Custom types added via [ParameterTypes.register] are stored here and are
/// visible to every [step] call in the same process.
final ParameterTypeRegistry defaultParameterTypes =
    ParameterTypeRegistry._mutable();

// ---------------------------------------------------------------------------
// ParameterTypes — public, backward-compatible API
// ---------------------------------------------------------------------------

/// Registers custom parameter types into the global [defaultParameterTypes].
///
/// Types added here are available to every [step] call that does not supply an
/// explicit `registry:` argument. Call this once during application startup,
/// before step definitions are evaluated.
///
/// For per-suite isolation (e.g. conflicting type names across test suites in
/// the same process) create a [ParameterTypeRegistry] and pass it directly to
/// [step] instead.
///
/// Example:
/// ```dart
/// ParameterTypes.register('color', r'(red|blue|green)', (v) => v);
/// step('I pick {color}', (ctx) async { ... });
/// ```
abstract final class ParameterTypes {
  /// Adds a parameter type named [name] to the global default registry.
  ///
  /// [regexPart] must include the outer capture group (e.g. `r'(red|green)'`).
  /// [parser] converts the captured string to [T].
  static void register<T>(
    String name,
    String regexPart,
    T Function(String) parser,
  ) {
    defaultParameterTypes._add(
      ParameterType<T>(name: name, regexPart: regexPart, parser: parser),
    );
  }
}
