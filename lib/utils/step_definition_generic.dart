import 'package:flutter_bdd_suite/utils/capture_token.dart';
import 'package:flutter_bdd_suite/utils/placeholders.dart';
import 'package:flutter_bdd_suite/world/widget_tester_world.dart';

class StepDefinitionGeneric {
  final RegExp pattern;
  final int argCount;
  final Future<void> Function(List<String>, WidgetTesterWorld) execute;

  StepDefinitionGeneric(this.pattern, this.argCount, this.execute);

  bool matches(String input) => pattern.hasMatch(input);

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

/// Defines a step with EXACTLY `expectedCaptureCount` captures (placeholder `{…}` or manual `( … )`):
///
/// ────  PLACEHOLDER TOKENS  ────
///
/// This method recognizes two built‐in placeholder tokens (keys in `placeholders`):
///
///  • `{string}`
///    • Internally backed by `regexPart = r'"(.*?)"'`
///    • Parser returns the exact text between the quotes (no further conversion).
///
///  • `{table}`
///    • Internally backed by `regexPart = r'"(<<<.+?>>>)"'`
///    • Parser strips `<<<` / `>>>` and feeds the remainder into `GherkinTable.fromJson(...)`.
///
/// At runtime, `{string}` and `{table}` count as exactly one capture each.
///
///
/// ────  MANUAL VS. NON-CAPTURING GROUPS  ────
///
///  • Manual capture `( … )`
///    – Any `(` not immediately preceded or followed by `?` is a “manual” capturing group.
///    – Example: `(foo|bar)`, `(\d+)`, `(urgent|normal)`.
///
///  • Non-capturing group `(?: … )`
///    – By default, `(?: … )` does NOT count as a capture.
///    – We rewrite **simple** `(?: <text> )?` → `( <text> )?` if `"<text>"` contains no `(` or `)`.
///      This makes an _optional literal fragment_ become a real capture (if there’s no nested parentheses).
///
///  • All other `(?…​)` forms (lookahead `(?=…)`, lookbehind `(?<=…)`, negative lookahead `(?!…)`, etc.)
///    are skipped entirely and never counted. We detect them by seeing `(` followed by `?`, then scanning past the matching `)`.
///    – They remain in the final regex but do not contribute to “capture count.”
///
/// *Note on “lookahead”:*
/// If you want to match and discard some literal text (e.g. ` into the search`), use a non‐capturing group, not a zero‐width lookahead. For example:
///
/// ```dart
/// // ✅ OK: consumes “ into the search”
/// r'I enter "(.*?)"(?: into the search)'
///
/// // ❌ Wrong: only asserts “ into the search” is next, but never consumes it
/// r'I enter "(.*?)"(?= into the search)'
/// ```
///
_ParsedStepRegex _buildStepRegex(String rawPattern, int expectedCaptureCount) {
  // Rewrite only those "(?: …)?" whose interior has NO "(" or ")".
  rawPattern = rawPattern.replaceAllMapped(
    RegExp(r'\(\?:(\s[^()]+?)\)\?'),
    (m) => '(${m.group(1)})?',
  );

  // Count placeholders "{Name}" (start with letter) in rawPattern.
  final placeholderMatches = RegExp(r'\{([A-Za-z]\w*)\}').allMatches(rawPattern);
  final placeholderCount = placeholderMatches.length;

  // Count manual "(…)" groups, ignoring ANY "(?…)".
  final manualPositions = <int>[];
  final openParRegex = RegExp(r'(?<!\?)\((?!\?)'); // "(" not preceded nor followed by "?"
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
      'generic$expectedCaptureCount requires exactly $expectedCaptureCount captures (sum of placeholders and manual groups). '
      'Found $placeholderCount placeholder(s) and $manualCount manual group(s) in:\n'
      '  $rawPattern',
    );
  }

  // Replace "{Token}" with its regex and collect PlaceholderDef.
  final placeholderDefs = <PlaceholderDef>[];
  var regexBody = rawPattern.replaceAllMapped(
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
      placeholderDefs.add(def);
      return def.regexPart;
    },
  );

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
      if (idx + 2 < rawPattern.length && rawPattern.substring(idx, idx + 3) == '(?:') {
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

  final totalLeftParens = RegExp(r'\(').allMatches(regexBody).length;
  final nonCaptureParens = RegExp(r'\(\?').allMatches(regexBody).length;
  final groupCount = totalLeftParens - nonCaptureParens;
  if (groupCount != expectedCaptureCount || ordered.length != expectedCaptureCount) {
    throw ArgumentError(
      'generic$expectedCaptureCount expects exactly $expectedCaptureCount capturing groups after replacement. '
      'Found $groupCount in regex:\n'
      '  $regexBody',
    );
  }

  final finalRegex = RegExp('^$regexBody\$');
  return _ParsedStepRegex(finalRegex, ordered);
}

/// Defines a step with no captures—just literal text (no regex at all).
StepDefinitionGeneric generic<W>(
    String rawPattern,
    Future<void> Function(W world) fn,
    ) {
  final escaped = RegExp.escape(rawPattern);
  final finalRegex = RegExp('^$escaped\$');
  return StepDefinitionGeneric(finalRegex, 0, (args, context) async {
    await fn(context as W);
  });
}

/// Defines a step with exactly one capture.
StepDefinitionGeneric generic1<T, W>(
  String rawPattern,
  Future<void> Function(T value, W world) fn,
) {
  final parsed = _buildStepRegex(rawPattern, 1);
  return StepDefinitionGeneric(parsed.regex, 1, (args, context) async {
    final raw = args[0];
    final token = parsed.tokens[0];
    final parsedValue = (token.kind == CaptureKind.placeholder)
        ? token.placeholderDef!.parser(raw)
        : raw;
    await fn(parsedValue as T, context as W);
  });
}

/// Defines a step with exactly two captures.
StepDefinitionGeneric generic2<T1, T2, W>(
  String rawPattern,
  Future<void> Function(T1, T2, W world) fn,
) {
  final parsed = _buildStepRegex(rawPattern, 2);
  return StepDefinitionGeneric(parsed.regex, 2, (args, context) async {
    final parsedArgs = <dynamic>[];
    for (var i = 0; i < 2; i++) {
      final raw = args[i].toString();
      final token = parsed.tokens[i];
      if (token.kind == CaptureKind.placeholder) {
        parsedArgs.add(token.placeholderDef!.parser(raw));
      } else {
        parsedArgs.add(raw);
      }
    }
    await fn(parsedArgs[0] as T1, parsedArgs[1] as T2, context as W);
  });
}

/// Defines a step with exactly three captures.
StepDefinitionGeneric generic3<T1, T2, T3, W>(
  String rawPattern,
  Future<void> Function(T1, T2, T3, W world) fn,
) {
  final parsed = _buildStepRegex(rawPattern, 3);
  return StepDefinitionGeneric(parsed.regex, 3, (args, context) async {
    final parsedArgs = <dynamic>[];
    for (var i = 0; i < 3; i++) {
      final raw = args[i].toString();
      final token = parsed.tokens[i];
      if (token.kind == CaptureKind.placeholder) {
        parsedArgs.add(token.placeholderDef!.parser(raw));
      } else {
        parsedArgs.add(raw);
      }
    }
    await fn(parsedArgs[0] as T1, parsedArgs[1] as T2, parsedArgs[2] as T3, context as W);
  });
}

/// Defines a step with exactly four captures.
StepDefinitionGeneric generic4<T1, T2, T3, T4, W>(
  String rawPattern,
  Future<void> Function(T1, T2, T3, T4, W world) fn,
) {
  final parsed = _buildStepRegex(rawPattern, 4);
  return StepDefinitionGeneric(parsed.regex, 4, (args, context) async {
    final parsedArgs = <dynamic>[];
    for (var i = 0; i < 4; i++) {
      final raw = args[i].toString();
      final token = parsed.tokens[i];
      if (token.kind == CaptureKind.placeholder) {
        parsedArgs.add(token.placeholderDef!.parser(raw));
      } else {
        parsedArgs.add(raw);
      }
    }
    await fn(parsedArgs[0] as T1, parsedArgs[1] as T2, parsedArgs[2] as T3, parsedArgs[3] as T4, context as W);
  });
}

/// Defines a step with exactly five captures.
StepDefinitionGeneric generic5<T1, T2, T3, T4, T5, W>(
  String rawPattern,
  Future<void> Function(T1, T2, T3, T4, T5, W world) fn,
) {
  final parsed = _buildStepRegex(rawPattern, 5);
  return StepDefinitionGeneric(parsed.regex, 5, (args, context) async {
    final parsedArgs = <dynamic>[];
    for (var i = 0; i < 5; i++) {
      final raw = args[i].toString();
      final token = parsed.tokens[i];
      if (token.kind == CaptureKind.placeholder) {
        parsedArgs.add(token.placeholderDef!.parser(raw));
      } else {
        parsedArgs.add(raw);
      }
    }
    await fn(parsedArgs[0] as T1, parsedArgs[1] as T2, parsedArgs[2] as T3, parsedArgs[3] as T4, parsedArgs[4] as T5, context as W);
  });
}

/// Defines a step with exactly six captures.
StepDefinitionGeneric generic6<T1, T2, T3, T4, T5, T6, W>(
  String rawPattern,
  Future<void> Function(T1, T2, T3, T4, T5, T6, W world) fn,
) {
  final parsed = _buildStepRegex(rawPattern, 6);
  return StepDefinitionGeneric(parsed.regex, 6, (args, context) async {
    final parsedArgs = <dynamic>[];
    for (var i = 0; i < 6; i++) {
      final raw = args[i].toString();
      final token = parsed.tokens[i];
      if (token.kind == CaptureKind.placeholder) {
        parsedArgs.add(token.placeholderDef!.parser(raw));
      } else {
        parsedArgs.add(raw);
      }
    }
    await fn(parsedArgs[0] as T1, parsedArgs[1] as T2, parsedArgs[2] as T3, parsedArgs[3] as T4, parsedArgs[4] as T5, parsedArgs[5] as T6, context as W);
  });
}
