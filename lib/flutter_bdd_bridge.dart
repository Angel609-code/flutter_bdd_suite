/// Dart-only bridge API for host-side integration helpers.
///
/// Import this library from scripts executed with `dart run` (for example,
/// bridge setup and CLI helpers). It intentionally avoids exporting Flutter
/// test APIs so it can run on the standalone Dart VM.
library;

export 'src/models/endpoint_registration_model.dart';
export 'src/server/integration_test_server.dart' hide EndpointHandler;
