import 'package:flutter_bdd_suite/flutter_bdd_suite.dart';

Future<IntegrationServerResult> sayHello() => bridgeGet('/hello');
