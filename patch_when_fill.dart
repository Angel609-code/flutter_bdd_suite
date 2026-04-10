import 'dart:io';

void main() {
  var file = File('lib/steps/when_fill_field_step.dart');
  var content = file.readAsStringSync();

  var newContent = content.replaceFirst('generic2<String, String, WidgetTesterWorld>(', 'step(');
  newContent = newContent.replaceFirst('(key, value, context) async {', '(ctx) async {\n      final key = ctx.args[0] as String;\n      final value = ctx.args[1] as String;');
  newContent = newContent.replaceAll('context.tester', 'ctx.tester');

  file.writeAsStringSync(newContent);
}
