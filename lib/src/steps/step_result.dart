import 'package:flutter_bdd_suite/src/models/gherkin_table_model.dart';

/// Canonical status for a completed step.
///
/// This lets callers branch on status without relying on runtime type checks.
enum StepStatus {
  /// The step executed successfully.
  success,

  /// The step was not executed because a previous step did not pass.
  skipped,

  /// No step definition matched this step text.
  undefined,

  /// A matching step definition signaled the step is work-in-progress.
  pending,

  /// A matching step definition threw an error.
  failure,

  /// More than one step definition matched, so execution was ambiguous.
  ambiguous;

  bool get blocksFollowingSteps => switch (this) {
    StepStatus.pending ||
    StepStatus.undefined ||
    StepStatus.failure ||
    StepStatus.ambiguous => true,
    StepStatus.success || StepStatus.skipped => false,
  };
}

sealed class StepResult {
  /// High-level outcome of this step.
  final StepStatus status;

  /// Original step text from the feature file.
  final String stepText;

  /// 1-based line number in the feature file.
  final int line;

  /// Elapsed execution time in microseconds, when available.
  final int? duration;

  /// The data table attached to this step, if any.
  final GherkinTable? table;

  /// The doc-string attached to this step, if any.
  final String? docString;

  const StepResult(
    this.stepText,
    this.line,
    this.duration, {
    required this.status,
    this.table,
    this.docString,
  });

  /// When Cucumber finds a matching step definition it executes it.
  /// If no error is raised, the step is marked as successful (green).
  factory StepResult.success(
    String stepText,
    int line,
    int? duration, {
    GherkinTable? table,
    String? docString,
  }) = _StepStatusResult.success;

  /// Steps after undefined, pending, failed, or ambiguous ones are not executed,
  /// even if a matching definition exists. These are marked as skipped (cyan).
  factory StepResult.skipped(
    String stepText,
    int line,
    int? duration, {
    GherkinTable? table,
    String? docString,
  }) = _StepStatusResult.skipped;

  /// When no matching step definition is found, the step is marked as
  /// undefined (yellow), and subsequent steps in the scenario are skipped.
  factory StepResult.undefined(
    String stepText,
    int line,
    int? duration, {
    GherkinTable? table,
    String? docString,
  }) = _StepStatusResult.undefined;

  /// When a step definition invokes pending logic (for example by throwing
  /// `PendingStepException`), the step is marked as pending (yellow).
  factory StepResult.pending(
    String stepText,
    int line,
    int? duration, {
    GherkinTable? table,
    String? docString,
  }) = _StepStatusResult.pending;
}

final class _StepStatusResult extends StepResult {
  const _StepStatusResult.success(
    super.stepText,
    super.line,
    super.duration, {
    super.table,
    super.docString,
  }) : super(status: StepStatus.success);

  const _StepStatusResult.skipped(
    super.stepText,
    super.line,
    super.duration, {
    super.table,
    super.docString,
  }) : super(status: StepStatus.skipped);

  const _StepStatusResult.undefined(
    super.stepText,
    super.line,
    super.duration, {
    super.table,
    super.docString,
  }) : super(status: StepStatus.undefined);

  const _StepStatusResult.pending(
    super.stepText,
    super.line,
    super.duration, {
    super.table,
    super.docString,
  }) : super(status: StepStatus.pending);
}

/// When a step definition's method is executed and raises an error, the step is marked as failed (red).
class StepFailure extends StepResult {
  final Object error;
  final StackTrace? stackTrace;

  const StepFailure(
    super.stepText,
    super.line,
    super.duration, {
    required this.error,
    this.stackTrace,
    super.table,
    super.docString,
  }) : super(status: StepStatus.failure);
}

/// Step definitions have to be unique for Cucumber to know what to execute. If more than one
/// step definition is matched for the same step, Cucumber can't resolve the ambiguity on its own.
class StepAmbiguous extends StepResult {
  final Object error;

  const StepAmbiguous(
    super.stepText,
    super.line,
    super.duration, {
    required this.error,
    super.table,
    super.docString,
  }) : super(status: StepStatus.ambiguous);
}
