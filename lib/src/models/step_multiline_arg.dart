import 'package:flutter_bdd_suite/src/models/gherkin_table_model.dart';

/// Union type representing the **optional** multiline argument attached to a
/// Gherkin step.
///
/// In Gherkin, a step can be followed by **at most one** multiline argument —
/// either a data table **or** a doc-string, never both. This sealed class
/// encodes that constraint at the type level, making impossible states
/// unrepresentable.
///
/// ---
///
/// **Pattern-match to handle each case:**
///
/// ```dart
/// switch (multilineArg) {
///   case StepTable(:final table):
///     for (final row in table.asMap()) { ... }
///   case StepDocString(:final content):
///     logLine(content);
///   case null:
///     // step has no multiline argument
/// }
/// ```
///
/// **Or use the convenience extension for quick access:**
///
/// ```dart
/// final table = multilineArg.table;     // null if not a StepTable
/// final doc   = multilineArg.docString; // null if not a StepDocString
/// ```
///
/// See also:
/// - [StepTable] — wraps a [GherkinTable] parsed from pipe-delimited rows.
/// - [StepDocString] — wraps verbatim text from a `"""` or ` ``` ` block.
sealed class StepMultilineArg {}

/// A data-table argument attached to a Gherkin step.
///
/// Created when the feature file has pipe-delimited rows immediately below the
/// step keyword:
///
/// ```gherkin
/// Given the following employees exist:
///   | name  | role      |
///   | Alice | Developer |
///   | Bob   | Designer  |
/// ```
class StepTable extends StepMultilineArg {
  /// The parsed table, with an optional [GherkinTable.header] and zero or more
  /// [GherkinTable.rows].
  final GherkinTable table;

  StepTable(this.table);
}

/// A doc-string argument attached to a Gherkin step.
///
/// Created when the feature file has a triple-quote (`"""`) or backtick-fence
/// (` ``` `) block immediately below the step keyword. The [content] is the
/// verbatim text inside the delimiters — no escaping applied.
///
/// ```gherkin
/// Then the response body should be:
///   """json
///   {"status": "ok"}
///   """
/// ```
///
/// The optional [mediaType] holds the hint text that follows the opening
/// delimiter on the same line (e.g. `json` in the example above). It is `null`
/// when no media-type hint is present.
class StepDocString extends StepMultilineArg {
  /// Raw multi-line content, preserved exactly as written in the feature file.
  final String content;

  /// Optional media-type hint from the opening delimiter line (e.g. `'json'`).
  ///
  /// Useful for deserialising the content as a specific format.
  final String? mediaType;

  StepDocString(this.content, {this.mediaType});
}

/// Convenience extension for extracting [StepMultilineArg] content without
/// a full pattern match.
///
/// Useful when a step is guaranteed to have a table or a doc-string and a
/// short access expression is preferred over a `switch`:
///
/// ```dart
/// // Quick access — returns null if wrong variant
/// final table = multilineArg.table;
/// final doc   = multilineArg.docString;
/// ```
extension StepMultilineArgX on StepMultilineArg? {
  /// Returns the [GherkinTable] if this is a [StepTable], otherwise `null`.
  GherkinTable? get table =>
      this is StepTable ? (this as StepTable).table : null;

  /// Returns [StepDocString.content] if this is a [StepDocString], otherwise
  /// `null`.
  String? get docString =>
      this is StepDocString ? (this as StepDocString).content : null;
}
