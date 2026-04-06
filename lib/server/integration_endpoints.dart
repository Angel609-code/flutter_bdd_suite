// ignore_for_file: avoid_print
import 'package:flutter_bdd_suite/server/bridge_client.dart';
import 'package:flutter_bdd_suite/models/integration_server_result_model.dart';
import 'package:flutter_bdd_suite/models/report_model.dart';

Future<IntegrationServerResult> saveReport(ReportBody report) => bridgePostJson('/save-report', body: report.toJson());
