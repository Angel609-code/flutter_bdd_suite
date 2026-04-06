import 'package:flutter_bdd_suite/server/integration_test_server.dart';

import 'integration_endpoints/endpoints.dart';

void registerBridgeEndpoints(IntegrationTestServer server) {
  EndpointUtils.addHelloEndpoint(server);
}