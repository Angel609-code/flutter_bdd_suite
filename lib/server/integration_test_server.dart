import 'dart:convert';
import 'dart:io';

import 'package:flutter_bdd_suite/models/endpoint_registration_model.dart';

typedef EndpointHandler = Future<void> Function(HttpRequest request);

/// A local HTTP server used as a bridge between the host machine and the device running the integration tests.
///
/// Because Flutter integration tests run on a device or emulator, they cannot directly access
/// the host machine's file system (e.g., to write test coverage or JSON reports). The `IntegrationTestServer`
/// runs on the host machine and listens for HTTP requests from the device to perform these host-side operations.
///
/// Users can extend this server's capabilities by registering custom endpoints using [registerEndpoint]
/// to run arbitrary code on the host machine triggered by the device under test.
class IntegrationTestServer {
  /// The port number this server listens on.
  final int port;
  HttpServer? _server;

  final Map<String, Map<String, EndpointHandler>> _custom = {
    'GET': {},
    'POST': {},
  };

  IntegrationTestServer({int? port})
      : port = port ?? int.tryParse(Platform.environment['FGP_BRIDGE_PORT'] ?? '') ?? 9876;

  /// Registers a custom HTTP endpoint handler.
  ///
  /// This allows test scripts on the device to trigger custom logic on the host machine
  /// during test execution.
  /// [registration] defines the method, path, and the callback function to handle the request.
  void registerEndpoint(EndpointRegistration registration) {
    final m = registration.method.toUpperCase();
    if (!_custom.containsKey(m)) {
      throw ArgumentError('Unsupported method $m');
    }
    if (_custom[m]!.containsKey(registration.path)) {
      throw ArgumentError('Handler for $m ${registration.path} already registered');
    }
    _custom[m]![registration.path] = registration.handler;
  }

  /// Starts the server and begins listening for incoming connections.
  Future<void> start() async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    } on SocketException catch (error) {
      throw StateError(
        'Failed to bind integration bridge server on port $port. '
        'Check bridge config or free the port. Original error: $error',
      );
    }
    _server!.listen((req) async {
      req.response.headers.set('Access-Control-Allow-Origin', '*');
      req.response.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
      req.response.headers.set('Access-Control-Allow-Headers', '*');
      req.response.headers.set('Access-Control-Allow-Private-Network', 'true');
      if (req.method == 'OPTIONS') {
        req.response.statusCode = 200;
        await req.response.close();
        return;
      }
      try {
        final method = req.method.toUpperCase();
        final handlers = {
          'POST': {
            '/save-report': _handleReport,
            ...?_custom['POST'],
          },
          'GET': {
            ...?_custom['GET'],
          },
        }[method];
        final handler = handlers?[req.uri.path];
        if (handler != null) {
          await handler(req);
        } else {
          req.response
            ..statusCode = handler != null ? 405 : 404
            ..write(handler != null ? 'Method not allowed' : 'Endpoint not found');
          await req.response.close();
        }
      } catch (e) {
        req.response
          ..statusCode = 500
          ..write('Server error: $e');
        await req.response.close();
      }
    });
    stdout.writeln('[IntegrationTestServer] Listening on port $port');
  }

  Future<void> _handleReport(HttpRequest req) async {
    try {
      final data = jsonDecode(await utf8.decoder.bind(req).join());
      String pathFromClient = data['path'];

      // 1. Get the Project Root (where the dev is running the app/test)
      final projectRoot = Directory.current.path;

      // 2. Build the Absolute Path
      // If the path is already absolute, use it. Otherwise, join it with project root.
      final absolutePath = pathFromClient.startsWith('/') 
          ? pathFromClient 
          : '$projectRoot/$pathFromClient';

      final file = File(absolutePath);

      // 3. Create directories if they don't exist and write
      await file.create(recursive: true);
      await file.writeAsString(data['content']);

      stdout.writeln('[IntegrationTestServer] Report saved at: $absolutePath');

      req.response
        ..statusCode = 200
        ..write('Report saved to $absolutePath');
    } catch (e) {
      req.response
        ..statusCode = 500
        ..write('Failed to save report: $e');
    } finally {
      await req.response.close();
    }
  }

  /// Stops the server and closes all active connections.
  Future<void> stop() async {
    await _server?.close(force: true);
    stdout.writeln('[IntegrationTestServer] Closed');
  }
}
