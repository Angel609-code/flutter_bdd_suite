import 'package:flutter_gherkin_parser/models/integration_server_result_model.dart';
import 'package:flutter_gherkin_parser/server/bridge_client.dart';

Future<IntegrationServerResult> sayHello() => bridgeGet('/hello');