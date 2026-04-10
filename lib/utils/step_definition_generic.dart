import 'package:flutter_bdd_suite/utils/capture_token.dart';
import 'package:flutter_bdd_suite/utils/placeholders.dart';
import 'package:flutter_bdd_suite/world/widget_tester_world.dart';

/// The concrete function type executed by the test runner for each matched step.
///
/// Receive the active [world]. Any attached data (table or doc-string) can be
/// accessed via [world.multilineArg] or the convenience shortcuts [world.table]
/// and [world.docString].
typedef StepFunction = Future<void> Function(WidgetTesterWorld world);

class StepDefinitionGeneric {
  final RegExp pattern;
  final int argCount;

  /// The internal executor called by [run].
  final Future<void> Function(List<String> args, WidgetTesterWorld world)
  execute;

  StepDefinitionGeneric(this.pattern, this.argCount, this.execute);

  bool matches(String input) => pattern.hasMatch(input);

  /// Run this step for the given [input] text.
  Future<void> run(String input, WidgetTesterWorld context) async {
    final match = pattern.firstMatch(input);
    if (match == null) throw Exception('No match for: $input');

    final args = <String>[];
    for (int i = 1; i <= argCount; i++) {
      args.add(match.group(i) ?? '');
    }

    await execute(args, context);
  }
}

class _ParsedStepRegex {
  final RegExp regex;
  final List<CaptureToken> tokens;

  _ParsedStepRegex(this.regex, this.tokens);
}

/// Defines a step with EXACTLY `expectedCaptureCount` captures
/// (placeholder `{…}` or manual `( … )`).
_ParsedStepRegex _buildStepRegex(String rawPattern, int expectedCaptureCount) {
  // Rewrite only those "(?: …)?" whose interior has NO "(" or ")".
  rawPattern = rawPattern.replaceAllMapped(
    RegExp(r'\(\?:(\s[^()]+?)\)\?'),
    (m) => '(${m.group(1)})?',
  );

  // Count placeholders "{Name}" (start with letter) in rawPattern.
  final placeholderMatches = RegExp(
    r'\{([A-Za-z]\w*)\}',
  ).allMatches(rawPattern);
  final placeholderCount = placeholderMatches.length;

  // Count manual "(…)" groups, ignoring ANY "(?…)".
  final manualPositions = <int>[];
  final openParRegex = RegExp(r'(?<!\?)\((?!\?)');
  var scanForManual = 0;
  while (true) {
    final m = openParRegex.firstMatch(rawPattern.substring(scanForManual));
    if (m == null) break;
    final pos = scanForManual + m.start;
    manualPositions.add(pos);
    scanForManual = pos + 1;
  }
  final manualCount = manualPositions.length;

  if (placeholderCount + manualCount != expectedCaptureCount) {
    throw ArgumentError(
      'generic$expectedCaptureCount requires exactly $expectedCaptureCount captures '
      '(sum of placeholders and manual groups). '
      'Found $placeholderCount placeholder(s) and $manualCount manual group(s) in:\n'
      '  $rawPattern',
    );
  }

  // Replace "{Token}" with its regex and collect PlaceholderDef.
  final placeholderDefs = <PlaceholderDef>[];
  var regexBody = rawPattern.replaceAllMapped(RegExp(r'\{([A-Za-z]\w*)\}'), (
    match,
  ) {
    final name = match.group(1)!;
    final def = placeholders[name];
    if (def == null) {
      throw ArgumentError(
        'Unsupported placeholder "{$name}". '
        'Supported tokens: ${placeholders.keys.join(", ")}.',
      );
    }
    placeholderDefs.add(def);
    return def.regexPart;
  });

  // Extract each manual "(…)" inner pattern from regexBody.
  final manualDefs = <String>[];
  final manualGroupRegex = RegExp(r'(?<!\?)\((?!\?)');
  var scanIndex = 0;
  while (true) {
    final m = manualGroupRegex.firstMatch(regexBody.substring(scanIndex));
    if (m == null) break;
    final start = scanIndex + m.start;
    var depth = 1;
    var i = start + 1;
    while (i < regexBody.length && depth > 0) {
      if (regexBody[i] == '(') {
        depth++;
      } else if (regexBody[i] == ')') {
        depth--;
      }
      i++;
    }
    final inner = regexBody.substring(start + 1, i - 1);
    manualDefs.add(inner);
    scanIndex = i;
  }

  // Build an ordered list of CaptureTokens (placeholder vs. manual).
  final ordered = <CaptureToken>[];
  var pIndex = 0, mIndex = 0;
  var idx = 0;
  while (idx < rawPattern.length) {
    final ph = RegExp(r'\{([A-Za-z]\w*)\}').matchAsPrefix(rawPattern, idx);
    if (ph != null) {
      ordered.add(CaptureToken.fromPlaceholder(placeholderDefs[pIndex++]));
      idx += ph.group(0)!.length;
      continue;
    }

    if (rawPattern[idx] == '(') {
      if (idx + 2 < rawPattern.length &&
          rawPattern.substring(idx, idx + 3) == '(?:') {
        idx += 3;
        continue;
      }
      if (idx + 1 < rawPattern.length && rawPattern[idx + 1] == '?') {
        var depth = 1;
        var i = idx + 2;
        while (i < rawPattern.length && depth > 0) {
          if (rawPattern[i] == '(') {
            depth++;
          } else if (rawPattern[i] == ')') {
            depth--;
          }
          i++;
        }
        idx = i;
        continue;
      }
      ordered.add(CaptureToken.fromManual(manualDefs[mIndex++]));
      idx += 1;
      continue;
    }

    idx++;
  }

  if (ordered.length != expectedCaptureCount) {
    throw ArgumentError(
      'generic$expectedCaptureCount expects exactly $expectedCaptureCount capturing '
      'groups after replacement. Found ${ordered.length} token(s) in pattern:\n'
      '  $rawPattern\n'
      'Expanded regex: $regexBody',
    );
  }

  final finalRegex = RegExp('^$regexBody\$');
  return _ParsedStepRegex(finalRegex, ordered);
}

/// Helper to parse arguments based on token definitions.
List<dynamic> _parseArgs(
  List<String> args,
  List<CaptureToken> tokens,
  int count,
) {
  return List.generate(count, (i) {
    final token = tokens[i];
    return token.kind == CaptureKind.placeholder
        ? token.placeholderDef!.parser(args[i])
        : args[i];
  });
}

// ──────────────────────────────────────────────────────────────────────────────
// Internal builder
// ──────────────────────────────────────────────────────────────────────────────

StepDefinitionGeneric _createGeneric<W>(
  String rawPattern,
  int count,
  Future<void> Function(List<dynamic> parsedArgs, W world) executor,
) {
  final parsed = _buildStepRegex(rawPattern, count);
  return StepDefinitionGeneric(parsed.regex, count, (args, context) async {
    final parsedArgs = _parseArgs(args, parsed.tokens, count);
    await executor(parsedArgs, context as W);
  });
}

// ──────────────────────────────────────────────────────────────────────────────
// PUBLIC GENERIC DEFINITIONS
// ──────────────────────────────────────────────────────────────────────────────
//
// These builders provide the simplest possible signature for step definitions.
// Any attached data (table or doc-string) is available via the world context:
//
//   generic('the following exist', (world) async {
//     final table = world.table;
//     ...
//   });

/// Alias for [WidgetTesterWorld], making step signatures read more naturally as
/// standard BDD context objects.
typedef StepContext = WidgetTesterWorld;

@Deprecated('Use step() instead for idiomatic BDD naming.')
StepDefinitionGeneric generic<W>(
  String rawPattern,
  Future<void> Function(W world) fn,
) => step<W>(rawPattern, fn);

/// Defines a step with 0 parameters.
StepDefinitionGeneric step<W>(
  String rawPattern,
  Future<void> Function(W ctx) fn,
) {
  final finalRegex = RegExp('^${RegExp.escape(rawPattern)}\$');
  return StepDefinitionGeneric(finalRegex, 0, (args, context) async {
    await fn(context as W);
  });
}

@Deprecated('Use step1() instead for idiomatic BDD naming.')
StepDefinitionGeneric generic1<T, W>(
  String rawPattern,
  Future<void> Function(T value, W world) fn,
) => step1<T, W>(rawPattern, fn);

/// Defines a step with exactly 1 parameter.
StepDefinitionGeneric step1<T, W>(
  String rawPattern,
  Future<void> Function(T value, W ctx) fn,
) => _createGeneric<W>(rawPattern, 1, (p, w) => fn(p[0] as T, w));

@Deprecated('Use step2() instead for idiomatic BDD naming.')
StepDefinitionGeneric generic2<T1, T2, W>(
  String rawPattern,
  Future<void> Function(T1, T2, W world) fn,
) => step2<T1, T2, W>(rawPattern, fn);

/// Defines a step with exactly 2 parameters.
StepDefinitionGeneric step2<T1, T2, W>(
  String rawPattern,
  Future<void> Function(T1, T2, W ctx) fn,
) => _createGeneric<W>(rawPattern, 2, (p, w) => fn(p[0] as T1, p[1] as T2, w));

@Deprecated('Use step3() instead for idiomatic BDD naming.')
StepDefinitionGeneric generic3<T1, T2, T3, W>(
  String rawPattern,
  Future<void> Function(T1, T2, T3, W world) fn,
) => step3<T1, T2, T3, W>(rawPattern, fn);

/// Defines a step with exactly 3 parameters.
StepDefinitionGeneric step3<T1, T2, T3, W>(
  String rawPattern,
  Future<void> Function(T1, T2, T3, W ctx) fn,
) => _createGeneric<W>(
  rawPattern,
  3,
  (p, w) => fn(p[0] as T1, p[1] as T2, p[2] as T3, w),
);

@Deprecated('Use step4() instead for idiomatic BDD naming.')
StepDefinitionGeneric generic4<T1, T2, T3, T4, W>(
  String rawPattern,
  Future<void> Function(T1, T2, T3, T4, W world) fn,
) => step4<T1, T2, T3, T4, W>(rawPattern, fn);

/// Defines a step with exactly 4 parameters.
StepDefinitionGeneric step4<T1, T2, T3, T4, W>(
  String rawPattern,
  Future<void> Function(T1, T2, T3, T4, W ctx) fn,
) => _createGeneric<W>(
  rawPattern,
  4,
  (p, w) => fn(p[0] as T1, p[1] as T2, p[2] as T3, p[3] as T4, w),
);

@Deprecated('Use step5() instead for idiomatic BDD naming.')
StepDefinitionGeneric generic5<T1, T2, T3, T4, T5, W>(
  String rawPattern,
  Future<void> Function(T1, T2, T3, T4, T5, W world) fn,
) => step5<T1, T2, T3, T4, T5, W>(rawPattern, fn);

/// Defines a step with exactly 5 parameters.
StepDefinitionGeneric step5<T1, T2, T3, T4, T5, W>(
  String rawPattern,
  Future<void> Function(T1, T2, T3, T4, T5, W ctx) fn,
) => _createGeneric<W>(
  rawPattern,
  5,
  (p, w) => fn(p[0] as T1, p[1] as T2, p[2] as T3, p[3] as T4, p[4] as T5, w),
);

@Deprecated('Use step6() instead for idiomatic BDD naming.')
StepDefinitionGeneric generic6<T1, T2, T3, T4, T5, T6, W>(
  String rawPattern,
  Future<void> Function(T1, T2, T3, T4, T5, T6, W world) fn,
) => step6<T1, T2, T3, T4, T5, T6, W>(rawPattern, fn);

/// Defines a step with exactly 6 parameters.
StepDefinitionGeneric step6<T1, T2, T3, T4, T5, T6, W>(
  String rawPattern,
  Future<void> Function(T1, T2, T3, T4, T5, T6, W ctx) fn,
) => _createGeneric<W>(
  rawPattern,
  6,
  (p, w) => fn(
    p[0] as T1,
    p[1] as T2,
    p[2] as T3,
    p[3] as T4,
    p[4] as T5,
    p[5] as T6,
    w,
  ),
);
