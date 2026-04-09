import 'package:flutter_bdd_suite/models/gherkin_table_model.dart';

abstract class StepResult {
  final String stepText;
  final int line;
  final int? duration;

  /// The data table attached to this step, if any.
  final GherkinTable? table;

  /// The doc-string attached to this step, if any.
  final String? docString;

  StepResult(
    this.stepText,
    this.line,
    this.duration, {
    this.table,
    this.docString,
  });
}

class StepSuccess extends StepResult {
  StepSuccess(
    super.stepText,
    super.line,
    super.duration, {
    super.table,
    super.docString,
  });
}

class StepSkipped extends StepResult {
  StepSkipped(
    super.stepText,
    super.line,
    super.duration, {
    super.table,
    super.docString,
  });
}

/// Represents a Gherkin step that is defined in a feature file but has no
/// corresponding Dart step implementation registered in [StepsRegistry].
///
/// This is different from [StepSkipped], which is used for steps that are
/// intentionally skipped due to a prior step failure. [StepPending] means
/// the automation is incomplete and needs to be written.
class StepPending extends StepResult {
  StepPending(
    super.stepText,
    super.line,
    super.duration, {
    super.table,
    super.docString,
  });
}

class StepFailure extends StepResult {
  final Object error;
  final StackTrace? stackTrace;

  StepFailure(
    super.stepText,
    super.line,
    super.duration, {
    required this.error,
    this.stackTrace,
    super.table,
    super.docString,
  });
}
