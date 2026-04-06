import 'package:flutter_bdd_suite/models/integration_server_result_model.dart';
import 'package:flutter_bdd_suite/server/bridge_client.dart';

Future<IntegrationServerResult> sayHello() => bridgeGet('/hello');