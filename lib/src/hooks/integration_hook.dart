import 'package:flutter_bdd_suite/src/lifecycle_listener.dart';

/// A base class for creating hooks that tap into the BDD test lifecycle.
///
/// Hooks allow you to execute custom code at specific points during the test suite execution.
/// By extending [IntegrationHook], you can override only the lifecycle methods you need,
/// such as setting up databases before a scenario, taking screenshots after a step fails,
/// or resetting state between features.
abstract class IntegrationHook extends LifecycleListener {
  // No additional members are required; all lifecycle methods are inherited from LifecycleListener.
}
