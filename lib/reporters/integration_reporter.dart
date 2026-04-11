import 'package:flutter_bdd_suite/lifecycle_listener.dart';

/// Base class for all test reporters.
///
/// A reporter observes the same [LifecycleListener] events as a hook but is
/// intended purely for output — collecting results, writing files, printing
/// summaries, etc.  Reporters never modify test execution state.
///
/// Register reporters via [IntegrationTestConfig.reporters].  All registered
/// reporters are notified at every lifecycle point alongside hooks.
///
/// Unlike [IntegrationHook], reporters are always unconditional: the
/// [tagExpression] is always `null` so that every scenario is captured in the
/// output regardless of tags.
///
/// Extend this class and override only the lifecycle methods you need, then
/// implement [toJson] to serialise any accumulated state.
abstract class IntegrationReporter implements LifecycleListener {
  /// Filesystem path used by reporters that write output to disk.
  ///
  /// Reporters that do not write files (e.g. console-only reporters) can leave
  /// this as the empty string, which is the default.
  final String path;

  IntegrationReporter({this.path = ''});

  /// Reporters run for every scenario regardless of tags.
  @override
  String? get tagExpression => null;

  /// Serialises the reporter's accumulated state to a JSON-compatible map.
  ///
  /// Used when the reporter's output needs to be embedded in a larger JSON
  /// document or sent over the bridge server.  Return an empty map `{}` if the
  /// reporter does not support JSON serialisation.
  Map<String, dynamic> toJson();
}
