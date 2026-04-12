import 'package:flutter_bdd_suite/flutter_bdd_bridge.dart';

import 'integration_endpoints/endpoints.dart';

void registerBridgeEndpoints(IntegrationTestServer server) {
  EndpointUtils.addHelloEndpoint(server);
}
