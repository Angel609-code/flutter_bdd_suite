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

/// When Cucumber finds a matching step definition it will execute it. If the block
/// in the step definition doesn't raise an error, the step is marked as successful (green).
class StepSuccess extends StepResult {
  StepSuccess(
    super.stepText,
    super.line,
    super.duration, {
    super.table,
    super.docString,
  });
}

/// Steps that follow undefined, pending, or failed steps are never executed, even if
/// there is a matching step definition. These steps are marked as skipped (cyan).
class StepSkipped extends StepResult {
  StepSkipped(
    super.stepText,
    super.line,
    super.duration, {
    super.table,
    super.docString,
  });
}

/// When Cucumber can't find a matching step definition, the step gets marked as
/// undefined (yellow), and all subsequent steps in the scenario are skipped.
class StepUndefined extends StepResult {
  StepUndefined(
    super.stepText,
    super.line,
    super.duration, {
    super.table,
    super.docString,
  });
}

/// When a step definition's method invokes the pending method (or throws PendingStepException),
/// the step is marked as pending (yellow, as with undefined ones), indicating that you have work to do.
class StepPending extends StepResult {
  StepPending(
    super.stepText,
    super.line,
    super.duration, {
    super.table,
    super.docString,
  });
}

/// When a step definition's method is executed and raises an error, the step is marked as failed (red).
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

/// Step definitions have to be unique for Cucumber to know what to execute. If more than one
/// step definition is matched for the same step, Cucucmber can't resolve the ambiguity on its own.
class StepAmbiguous extends StepResult {
  final Object error;

  StepAmbiguous(
    super.stepText,
    super.line,
    super.duration, {
    required this.error,
    super.table,
    super.docString,
  });
}
