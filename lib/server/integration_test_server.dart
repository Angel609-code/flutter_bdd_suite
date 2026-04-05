// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:flutter_gherkin_parser/models/endpoint_registration_model.dart';

typedef EndpointHandler = Future<void> Function(HttpRequest request);

class IntegrationTestServer {
  final int port = 9876;
  HttpServer? _server;

  final Map<String, Map<String, EndpointHandler>> _custom = {
    'GET': {},
    'POST': {},
  };

  IntegrationTestServer();

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

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _server!.listen((req) async {
      req.response.headers.set('Access-Control-Allow-Origin', '*');
      req.response.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
      req.response.headers.set('Access-Control-Allow-Headers', '*');
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
    print('[IntegrationTestServer] Listening on port $port');
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

      print('[IntegrationTestServer] Report saved at: $absolutePath');

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

  Future<void> stop() async {
    await _server?.close(force: true);
    print('[IntegrationTestServer] Closed');
  }
}
