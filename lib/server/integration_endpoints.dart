// ignore_for_file: avoid_print
import 'package:flutter_bdd_suite/server/bridge_client.dart';
import 'package:flutter_bdd_suite/models/integration_server_result_model.dart';
import 'package:flutter_bdd_suite/models/report_model.dart';

/// Sends a report payload to the host machine's `IntegrationTestServer` to be saved to disk.
///
/// This is typically called by a reporter (like `JsonReporter`) running on the device to persist
/// test results to the host file system.
Future<IntegrationServerResult> saveReport(ReportBody report) => bridgePostJson('/save-report', body: report.toJson());
