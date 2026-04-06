// ignore_for_file: avoid_print
import 'package:flutter_bdd_suite/models/gherkin_table_model.dart';
import 'package:flutter_bdd_suite/utils/step_definition_generic.dart';
import 'package:flutter_bdd_suite/world/widget_tester_world.dart';

StepDefinitionGeneric andPrintTable() {
  return generic1<GherkinTable, WidgetTesterWorld>(
    'I print table {table}', (table, context) async {
      print(table.toJson());
    },
  );
}