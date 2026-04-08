import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bdd_suite/server/bridge_client.dart';

const _bridgeLogsEnabled =
    String.fromEnvironment('FGP_BRIDGE_LOGS', defaultValue: 'false') == 'true';

void logLine(String message) {
  debugPrintSynchronously(message);

  if (!_bridgeLogsEnabled) {
    return;
  }

  unawaited(
    bridgePostJson(
      '/log',
      body: <String, dynamic>{
        'message': message,
      },
    ),
  );
}