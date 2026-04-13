import 'package:flutter/foundation.dart';

/// Interface for logging library output.
abstract interface class BddLogger {
  void write(String message);
}

/// Standard implementation of [BddLogger] that prints directly to the console.
class StdoutBddLogger implements BddLogger {
  @override
  void write(String message) {
    debugPrintSynchronously(message);
  }
}

/// Global logger instance, defaults to [StdoutBddLogger].
BddLogger bddLogger = StdoutBddLogger();

/// Gateway for backward compatibility.
void logLine(String message) {
  bddLogger.write(message);
}
