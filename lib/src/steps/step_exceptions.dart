/// Exception thrown when multiple step definitions match a single step text.
class AmbiguousStepException implements Exception {
  final String message;

  AmbiguousStepException(this.message);

  @override
  String toString() => message;
}

/// Exception thrown by a step implementation to indicate it is pending.
class PendingStepException implements Exception {
  final String message;

  PendingStepException([this.message = 'The step is pending.']);

  @override
  String toString() => message;
}
