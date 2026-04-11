import 'package:flutter_bdd_suite/utils/placeholders.dart';
import 'package:flutter_bdd_suite/world/widget_tester_world.dart';
import 'package:flutter_bdd_suite/utils/step_args.dart';
import 'package:flutter_bdd_suite/models/gherkin_table_model.dart';
import 'package:flutter_bdd_suite/models/step_multiline_arg.dart';
import 'package:flutter_test/flutter_test.dart';

/// The execution context for a single step.
///
/// Contains the typed [args] parsed from the step text, the Flutter [tester],
/// the active [world] state, and any attached multiline arguments via
/// [table] and [docString].
class StepContext {
  final WidgetTester tester;
  final WidgetTesterWorld world;
  final StepArgs args;
  final StepMultilineArg? _multilineArg;

  StepContext({
    required this.tester,
    required this.world,
    required this.args,
    StepMultilineArg? multilineArg,
  }) : _multilineArg = multilineArg;

  /// Returns the attached data table.
  ///
  /// Throws a [StateError] if this step has no table argument.
  GherkinTable table() {
    final t = _multilineArg?.table;
    if (t == null) {
      throw StateError(
        'Expected a DataTable attached to this step, but none was found.',
      );
    }

    return t;
  }

  /// Returns the attached doc-string content.
  ///
  /// Throws a [StateError] if this step has no doc-string argument.
  String docString() {
    final d = _multilineArg?.docString;
    if (d == null) {
      throw StateError(
        'Expected a DocString attached to this step, but none was found.',
      );
    }

    return d;
  }
}

/// Type definition for resolved step functions.
///
/// Receive the active [world]. Any attached data (table or doc-string) can be
/// accessed via [world.multilineArg] or the convenience shortcuts [world.table]
/// and [world.docString].
typedef StepFunction = Future<void> Function(WidgetTesterWorld world);


/// The callback signature for user-defined steps.
typedef StepAction = Future<void> Function(StepContext ctx);

class StepDefinitionGeneric {
  final RegExp pattern;
  final Future<void> Function(
    List<String> args,
    WidgetTesterWorld world,
    StepMultilineArg? multilineArg,
  )
  execute;

  StepDefinitionGeneric(this.pattern, this.execute);

  bool matches(String input) => pattern.hasMatch(input);

  Future<void> run(
    String input,
    WidgetTesterWorld world, [
    StepMultilineArg? multilineArg,
  ]) async {
    final match = pattern.firstMatch(input);
    if (match == null) throw Exception('No match for: $input');

    final args = <String>[];
    for (int i = 1; i <= match.groupCount; i++) {
      args.add(match.group(i) ?? '');
    }

    await execute(args, world, multilineArg);
  }
}

class _ParsedStepRegex {
  final RegExp regex;
  final List<ParameterType<dynamic>> tokens;

  _ParsedStepRegex(this.regex, this.tokens);
}

/// Rejects raw regex syntax that has no meaning in Cucumber Expressions.
///
/// Called at registration time so the error surfaces immediately, not at
/// match time deep inside a test run.
void _validateCucumberExpression(String pattern) {
  // Sequences that are unambiguously regex and never valid Cucumber text.
  const regexOnlySequences = [
    '(?:', // non-capturing group
    '(?=', // positive lookahead
    '(?!', // negative lookahead
    r'\d', // digit shorthand
    r'\w', // word shorthand
    r'\s', // whitespace shorthand
    '[', // character class
    '|', // alternation — use stepRegExp() for alternatives
  ];
  for (final seq in regexOnlySequences) {
    if (pattern.contains(seq)) {
      throw ArgumentError(
        'Invalid Cucumber expression: "$pattern".\n'
        'The sequence "$seq" is regex syntax and is not allowed in step().\n'
        'For advanced patterns, use stepRegExp() instead.',
      );
    }
  }

  // Anchors at the boundaries mean the user is writing regex, not a
  // Cucumber Expression. The engine adds anchors automatically.
  if (pattern.startsWith('^')) {
    throw ArgumentError(
      'Invalid Cucumber expression: "$pattern".\n'
      'Expressions must not start with ^; the engine anchors them automatically.\n'
      'Use stepRegExp() if you need explicit anchoring.',
    );
  }
  if (pattern.endsWith('\$')) {
    throw ArgumentError(
      'Invalid Cucumber expression: "$pattern".\n'
      'Expressions must not end with \$; the engine anchors them automatically.\n'
      'Use stepRegExp() if you need explicit anchoring.',
    );
  }

  // Unescaped parentheses are not valid in Cucumber Expression syntax.
  if (RegExp(r'(?<!\\)[()]').hasMatch(pattern)) {
    throw ArgumentError(
      'Invalid Cucumber expression: "$pattern".\n'
      'Unescaped parentheses are not allowed in step().\n'
      'Use stepRegExp() for capturing groups.',
    );
  }
}

/// Rejects Cucumber Expression placeholders accidentally used inside stepRegExp.
void _validateRawRegExp(RegExp pattern) {
  final cucumberToken = RegExp(r'\{[A-Za-z]\w*\}');
  if (cucumberToken.hasMatch(pattern.pattern)) {
    final found = cucumberToken
        .allMatches(pattern.pattern)
        .map((m) => m.group(0)!)
        .join(', ');
    throw ArgumentError(
      'stepRegExp() received Cucumber Expression token(s): $found\n'
      'Use step() for {placeholder} patterns, or replace them with '
      'explicit regex capture groups in stepRegExp().',
    );
  }
}

/// Compiles a Cucumber-style expression (with `{...}` placeholders) into a RegExp.
_ParsedStepRegex _compileExpression(
  String rawPattern,
  ParameterTypeRegistry registry,
) {
  _validateCucumberExpression(rawPattern);
  final tokens = <ParameterType<dynamic>>[];

  // Escape the literal parts of the pattern so that dots, parens, etc. in
  // the user's step text are treated as literals and not as regex syntax.
  var escapedPattern = RegExp.escape(rawPattern);

  // RegExp.escape turns `{word}` into `\{word\}`. Un-escape those braces so
  // the substitution loop below can recognise them.
  escapedPattern = escapedPattern.replaceAllMapped(
    RegExp(r'\\\{([A-Za-z]\w*)\\\}'),
    (m) => '{${m.group(1)!}}',
  );

  // Replace each `{name}` with the corresponding regex fragment.
  final regexBody = escapedPattern.replaceAllMapped(
    RegExp(r'\{([A-Za-z]\w*)\}'),
    (match) {
      final name = match.group(1)!;
      final type = registry.resolve(name); // throws a clear error if unknown
      tokens.add(type);
      return type.regexPart;
    },
  );

  return _ParsedStepRegex(RegExp('^$regexBody\$'), tokens);
}

/// Registers a step using Cucumber Expression semantics (`{string}`, `{int}`, etc.).
///
/// The [pattern] is compiled to a [RegExp] once at registration time — never at
/// match time — so there is no per-scenario compilation cost.
///
/// **Custom parameter types** can be supplied in two ways:
///
/// 1. **Global (default):** call [ParameterTypes.register] before any step
///    definitions are evaluated. All [step] calls that omit `registry:` share
///    the global [defaultParameterTypes].
///
/// 2. **Per-suite (isolated):** pass an explicit [ParameterTypeRegistry] to
///    `registry:`. Types in this registry are completely independent of the
///    global one.
///
/// Example:
/// ```dart
/// // Globally registered type — no registry: argument needed.
/// ParameterTypes.register('color', r'(red|blue|green)', (v) => v);
/// step('I pick {color}', (ctx) async { ... });
///
/// // Per-suite isolated type.
/// final reg = ParameterTypeRegistry(additionalTypes: [
///   ParameterType(name: 'role', regexPart: r'(admin|guest)', parser: Role.parse),
/// ]);
/// step('I log in as {role}', action, registry: reg);
/// ```
StepDefinitionGeneric step(
  String pattern,
  StepAction action, {
  ParameterTypeRegistry? registry,
}) {
  final compiled = _compileExpression(
    pattern,
    registry ?? defaultParameterTypes,
  );
  return StepDefinitionGeneric(compiled.regex, (rawArgs, world, multilineArg) async {
    final List<Object?> parsedArgs = [
      for (int i = 0; i < compiled.tokens.length; i++)
        compiled.tokens[i].parser(rawArgs[i]),
    ];
    final ctx = StepContext(
      tester: world.tester,
      world: world,
      args: StepArgs(parsedArgs, debugSource: 'Pattern: $pattern'),
      multilineArg: multilineArg,
    );
    await action(ctx);
  });
}

/// Registers a step using standard Dart [RegExp] semantics.
///
/// Use this for patterns that require regex features not supported by Cucumber
/// Expressions: alternations (`a|b`), lookaheads, character classes, etc.
///
/// Capture groups `(...)` become positional entries in `ctx.args`. Pass
/// [converters] to type-cast each captured string — the list must match the
/// number of capture groups exactly. Non-capturing groups `(?:...)` do not
/// produce args entries.
///
/// The pattern is automatically anchored (`^…$`) if it is not already, so
/// partial matches are never returned.
///
/// Example:
/// ```dart
/// stepRegExp(
///   RegExp(r'I wait (\d+) (second|minute)s?'),
///   (ctx) async {
///     final (amount, unit) = ctx.args.two<int, String>();
///     ...
///   },
///   converters: [int.parse, (s) => s],
/// );
/// ```
StepDefinitionGeneric stepRegExp(
  RegExp pattern,
  StepAction action, {
  List<Object? Function(String)>? converters,
}) {
  _validateRawRegExp(pattern);

  // Auto-anchor the pattern so it always matches the full step text.
  var src = pattern.pattern;
  if (!src.startsWith('^')) src = '^$src';
  if (!src.endsWith('\$')) src = '$src\$';

  final anchored = RegExp(
    src,
    caseSensitive: pattern.isCaseSensitive,
    multiLine: pattern.isMultiLine,
    dotAll: pattern.isDotAll,
    unicode: pattern.isUnicode,
  );

  return StepDefinitionGeneric(anchored, (rawArgs, world, multilineArg) async {
    // If converters were supplied, their count must equal the number of
    // captured groups; a mismatch means the caller made a configuration error
    // that would otherwise surface as a confusing type error later.
    if (converters != null && converters.length != rawArgs.length) {
      throw ArgumentError(
        'stepRegExp: converters.length (${converters.length}) must equal '
        'the number of captured groups (${rawArgs.length}) '
        'for pattern: ${pattern.pattern}',
      );
    }

    final List<Object?> parsedArgs = (converters != null)
        ? [for (int i = 0; i < rawArgs.length; i++) converters[i](rawArgs[i])]
        : rawArgs;

    final ctx = StepContext(
      tester: world.tester,
      world: world,
      args: StepArgs(parsedArgs, debugSource: 'RegExp: ${pattern.pattern}'),
      multilineArg: multilineArg,
    );
    await action(ctx);
  });
}
