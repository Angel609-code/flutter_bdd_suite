
/// The core World interface representing scenario-level state.
///
/// The framework creates a fresh instance of [World] before each scenario.
/// Advanced users can subclass [World] to provide strongly-typed state:
///
/// ```dart
/// class MyWorld extends World {
///   User? currentUser;
/// }
/// ```
abstract class World {
  /// A simple place to stash any shared data (keyed by String) during the run.
  void setAttachment<T>(String key, T value);

  /// Retrieve a previously-stored attachment (or null).
  T? getAttachment<T>(String key);
}
