import 'package:flutter_bdd_suite/utils/placeholders.dart';
import 'package:flutter_bdd_suite/world/widget_tester_world.dart';
import 'package:flutter_bdd_suite/models/gherkin_table_model.dart';
import 'package:flutter_bdd_suite/models/step_multiline_arg.dart';
import 'package:flutter_test/flutter_test.dart';

/// The execution context for a single step.
///
/// Contains the typed [args] parsed from the step text, the Flutter [tester],
/// the active [world] state, and any attached [table] or [docString].
class StepContext {
  final WidgetTester tester;
  final WidgetTesterWorld world;
  final List<dynamic> args;
  final StepMultilineArg? _multilineArg;

  StepContext({
    required this.tester,
    required this.world,
    required this.args,
    StepMultilineArg? multilineArg,
  }) : _multilineArg = multilineArg;

  GherkinTable? get table => _multilineArg?.table;
  String? get docString => _multilineArg?.docString;
}

/// The concrete function type executed by the test runner for each matched step.
typedef StepFunction = Future<void> Function(WidgetTesterWorld world);

/// The callback signature for user-defined steps.
typedef StepAction = Future<void> Function(StepContext ctx);

class StepDefinitionGeneric {
  final RegExp pattern;
  final Future<void> Function(List<String> args, WidgetTesterWorld world)
  execute;

  StepDefinitionGeneric(this.pattern, this.execute);

  bool matches(String input) => pattern.hasMatch(input);

  Future<void> run(String input, WidgetTesterWorld world, [StepMultilineArg? multilineArg]) async {
    final match = pattern.firstMatch(input);
    if (match == null) throw Exception('No match for: $input');

    final args = <String>[];
    for (int i = 1; i <= match.groupCount; i++) {
      args.add(match.group(i) ?? '');
    }

    await execute(args, world);
  }
}

class _ParsedStepRegex {
  final RegExp regex;
  final List<PlaceholderDef> tokens;

  _ParsedStepRegex(this.regex, this.tokens);
}

/// Compiles a Cucumber-style expression (with `{...}` placeholders) into a RegExp.
_ParsedStepRegex _compileExpression(String rawPattern) {
  final tokens = <PlaceholderDef>[];

  // Escape the pattern first, but temporarily un-escape our {} blocks so we can process them
  var escapedPattern = RegExp.escape(rawPattern);
  escapedPattern = escapedPattern.replaceAllMapped(
    RegExp(r'\\\{([A-Za-z]\w*)\\\}'),
    (m) => '{' + m.group(1)! + '}',
  );

  final regexBody = escapedPattern.replaceAllMapped(
    RegExp(r'\{([A-Za-z]\w*)\}'),
    (match) {
      final name = match.group(1)!;
      final def = placeholders[name];
      if (def == null) {
        throw ArgumentError(
          'Unsupported placeholder "{$name}". '
          'Supported tokens: ${placeholders.keys.join(", ")}.',
        );
      }
      tokens.add(def);
      return def.regexPart;
    },
  );

  final finalRegex = RegExp('^${regexBody}\$');
  return _ParsedStepRegex(finalRegex, tokens);
}

/// Registers a step using Cucumber Expression semantics (`{string}`, `{int}`, etc.).
StepDefinitionGeneric step(String pattern, StepAction action) {
  final compiled = _compileExpression(pattern);
  return StepDefinitionGeneric(compiled.regex, (rawArgs, world) async {
    final parsedArgs = <dynamic>[];
    for (int i = 0; i < compiled.tokens.length; i++) {
      parsedArgs.add(compiled.tokens[i].parser(rawArgs[i]));
    }
    final ctx = StepContext(
      tester: world.tester,
      world: world,
      args: parsedArgs,
      multilineArg: null /* multiline arg is injected at runner */,
    );
    await action(ctx);
  });
}

/// Registers a step using standard Dart RegExp semantics.
///
/// Capture groups `(...)` become `ctx.args`. Non-capturing groups `(?:...)` are ignored.
StepDefinitionGeneric stepRegExp(RegExp pattern, StepAction action) {
  // Ensure the regex is anchored if it isn't already to match full lines correctly.
  var regexPattern = pattern.pattern;
  if (!regexPattern.startsWith('^')) regexPattern = '^$regexPattern';
  if (!regexPattern.endsWith('\$')) regexPattern = '$regexPattern\$';

  final anchoredPattern = RegExp(
    regexPattern,
    caseSensitive: pattern.isCaseSensitive,
    multiLine: pattern.isMultiLine,
    dotAll: pattern.isDotAll,
    unicode: pattern.isUnicode,
  );

  return StepDefinitionGeneric(anchoredPattern, (rawArgs, world) async {
    final ctx = StepContext(
      tester: world.tester,
      world: world,
      args: rawArgs, // Raw strings from regex capture groups
      multilineArg: null /* multiline arg is injected at runner */,
    );
    await action(ctx);
  });
}
