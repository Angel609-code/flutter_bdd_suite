/// Configuration model for report presentation.
class ReportPresentation {
  /// Whether to use ANSI color codes in the console output.
  final bool useColors;

  /// Whether to include file paths and line numbers in step output.
  final bool showStepPaths;

  /// Whether to show only steps that were actually executed.
  final bool showOnlyExecutedSteps;


  /// Whether to show full stack traces for failed steps.
  final bool showStackTraces;

  const ReportPresentation({
    this.useColors = true,
    this.showStepPaths = false,
    this.showOnlyExecutedSteps = true,
    this.showStackTraces = false,
  });

  /// Creates a copy of this presentation with the given fields replaced.
  ReportPresentation copyWith({
    bool? useColors,
    bool? showStepPaths,
    bool? showOnlyExecutedSteps,
    bool? showStackTraces,
  }) {
    return ReportPresentation(
      useColors: useColors ?? this.useColors,
      showStepPaths: showStepPaths ?? this.showStepPaths,
      showOnlyExecutedSteps:
          showOnlyExecutedSteps ?? this.showOnlyExecutedSteps,
      showStackTraces: showStackTraces ?? this.showStackTraces,
    );
  }
}
