import 'dart:io';
import 'dart:convert';

import 'package:flutter_bdd_suite/src/models/integration_server_result_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const String _bridgeHostFromDefine = String.fromEnvironment(
  'FGP_BRIDGE_HOST',
  defaultValue: '',
);
const String _bridgePortFromDefine = String.fromEnvironment(
  'FGP_BRIDGE_PORT',
  defaultValue: '9876',
);

String resolveBridgeHost() {
  if (_bridgeHostFromDefine.isNotEmpty) {
    return _bridgeHostFromDefine;
  }

  if (kIsWeb) {
    return '127.0.0.1';
  }

  return Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
}

int resolveBridgePort() {
  return int.tryParse(_bridgePortFromDefine) ?? 9876;
}

Uri buildBridgeUri(String path) {
  final normalizedPath = path.startsWith('/') ? path : '/$path';
  return Uri.parse(
    'http://${resolveBridgeHost()}:${resolveBridgePort()}$normalizedPath',
  );
}

Future<IntegrationServerResult> bridgeGet(
  String path, {
  Map<String, String>? headers,
}) async {
  try {
    final response = await http.get(buildBridgeUri(path), headers: headers);
    return _toIntegrationResult(response);
  } catch (error) {
    return _networkErrorResult(error);
  }
}

Future<IntegrationServerResult> bridgePostJson(
  String path, {
  Object? body,
  Map<String, String>? headers,
}) async {
  final resolvedHeaders = <String, String>{
    'Content-Type': 'application/json',
    ...?headers,
  };

  try {
    final response = await http.post(
      buildBridgeUri(path),
      headers: resolvedHeaders,
      body: body == null ? null : jsonEncode(body),
    );
    return _toIntegrationResult(response);
  } catch (error) {
    return _networkErrorResult(error);
  }
}

IntegrationServerResult _toIntegrationResult(http.Response response) {
  return IntegrationServerResult(
    success: response.statusCode == 200,
    statusCode: response.statusCode,
    message: response.body,
  );
}

IntegrationServerResult _networkErrorResult(Object error) {
  return IntegrationServerResult(
    success: false,
    statusCode: -1,
    message: error.toString(),
  );
}
