import 'dart:convert' show jsonEncode;

import 'package:flutter_bdd_suite/models/gherkin_table_model.dart';

/// A single parsed Gherkin step.
///
/// [table] and [docString] are **first-class properties**, populated by the
/// parser when a data table or doc-string block immediately follows the step
/// line in the feature file. They are **never** embedded inside [text].
class Step {
  /// The bare step text (keyword + description), with no embedded delimiters.
  final String text;

  /// The 1-based line number of the step keyword in the feature file.
  final int line;

  /// An optional Gherkin data table attached to this step.
  ///
  /// Non-null when the feature file has a pipe-delimited table directly below
  /// the step keyword.
  final GherkinTable? table;

  /// An optional doc-string attached to this step.
  ///
  /// Non-null when the feature file has a triple-quote (`"""`) or
  /// backtick-fence (` ``` `) block directly below the step keyword.
  final String? docString;

  Step({required this.text, required this.line, this.table, this.docString});

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'line': line,
      // Omit null fields to keep the JSON compact.
      if (table != null) 'table': table!.toJsonMap(),
      if (docString != null) 'docString': docString,
    };
  }

  factory Step.fromJson(Map<String, dynamic> json) {
    GherkinTable? table;
    if (json.containsKey('table') && json['table'] != null) {
      table = GherkinTable.fromJsonMap(json['table'] as Map<String, dynamic>);
    }
    return Step(
      text: json['text'] as String,
      line: json['line'] as int,
      table: table,
      docString: json['docString'] as String?,
    );
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
