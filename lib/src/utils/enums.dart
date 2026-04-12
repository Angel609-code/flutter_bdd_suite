/// Internal reporting status used by [SummaryReporter] and similar reporters
/// to track the outcome of the currently executing scenario on a step-by-step basis.
///
/// Unlike [ScenarioExecutionStatus], which is the authoritative post-run result
/// stored in [ScenarioResult], this enum is updated incrementally as each step
/// completes so that reporters can count scenarios by their final outcome inside
/// [LifecycleListener.onAfterScenario].
enum ScenarioStatus {
  /// All steps executed so far have passed.
  passed,

  /// At least one step failed, was pending, undefined, or ambiguous.
  failed,

  /// Steps were skipped because a prior step did not pass; no step has
  /// actually failed (i.e. the failure occurred in a preceding scenario's
  /// background).
  skipped,
}
