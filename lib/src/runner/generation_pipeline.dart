import 'dart:convert' show jsonEncode;
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter_bdd_suite/src/utils/expression_evaluator.dart';
import 'package:flutter_bdd_suite/src/utils/feature_parser.dart';
import 'package:mustache_template/mustache_template.dart';
import 'package:path/path.dart' as p;

class GeneratePipelineOptions {
  final String cwd;
  final String configPath;
  final String order;
  final String? pattern;
  final String? tags;

  const GeneratePipelineOptions({
    required this.cwd,
    required this.configPath,
    this.order = 'none',
    this.pattern,
    this.tags,
  });
}

class GeneratePipelineResult {
  final int generatedCount;
  final String masterRunnerPath;

  const GeneratePipelineResult({
    required this.generatedCount,
    required this.masterRunnerPath,
  });
}

Future<GeneratePipelineResult> runGeneratePipeline(
  GeneratePipelineOptions options,
) async {
  final configFile = File(
    p.join(options.cwd, 'integration_test', options.configPath),
  );
  if (!configFile.existsSync()) {
    throw StateError(
      'Cannot find config at integration_test/${options.configPath}',
    );
  }

  TagExpr? tagFilter;
  if (options.tags != null && options.tags!.trim().isNotEmpty) {
    tagFilter = parseTagExpression(options.tags!);
  }

  final selectedTagFilter = tagFilter;

  final featuresDir = Directory(
    p.join(options.cwd, 'integration_test', 'features'),
  );
  if (!featuresDir.existsSync()) {
    throw StateError(
      'No integration_test/features folder found under ${options.cwd}',
    );
  }

  final parser = FeatureParser();
  List<File> featureFiles =
      featuresDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.feature'))
          .toList();

  if (options.pattern != null && options.pattern!.isNotEmpty) {
    final regex = RegExp(options.pattern!);
    featureFiles =
        featureFiles.where((f) {
          final relPath = p.relative(f.path, from: featuresDir.path);
          return regex.hasMatch(relPath);
        }).toList();
  }

  final generatedRoot = Directory(
    p.join(options.cwd, 'integration_test', 'generated'),
  );
  if (generatedRoot.existsSync()) {
    generatedRoot.deleteSync(recursive: true);
  }
  generatedRoot.createSync(recursive: true);

  final templateUri = await Isolate.resolvePackageUri(
    Uri.parse(
      'package:flutter_bdd_suite/src/templates/test_runner_template.mustache',
    ),
  );
  if (templateUri == null) {
    throw StateError('Cannot resolve template URI');
  }

  final templateFile = File.fromUri(templateUri);
  if (!templateFile.existsSync()) {
    throw StateError('Cannot find template at ${templateFile.path}');
  }

  final template = Template(
    templateFile.readAsStringSync(),
    htmlEscapeValues: false,
  );
  int generatedCount = 0;

  for (final featureFile in featureFiles) {
    final relPath = p.relative(featureFile.path, from: featuresDir.path);
    final raw = featureFile.readAsStringSync();
    final feature = parser.parse(raw, relPath);

    if (selectedTagFilter != null) {
      final kept =
          feature.scenarios.where((sc) {
            final tags = {...feature.tags, ...sc.tags}.toSet();
            return selectedTagFilter.evaluate(tags);
          }).toList();

      if (kept.isEmpty) {
        stdout.writeln(
          'Skipping ${feature.name}, no scenarios match ${options.tags}',
        );
        continue;
      }

      feature.scenarios
        ..clear()
        ..addAll(kept);
    }

    final featureCount =
        RegExp(r'^\s*Feature:', multiLine: true).allMatches(raw).length;
    if (featureCount != 1) {
      throw StateError('Expected one Feature in ${featureFile.path}');
    }

    // We allow multiple Backgrounds now (one per Feature, and one per Rule).
    // The parser handles appending Rule Backgrounds to Scenarios.

    final scenarioMaps = <Map<String, dynamic>>[];
    for (var i = 0; i < feature.scenarios.length; i++) {
      final sc = feature.scenarios[i];
      final scTagsUnique = sc.tags.toSet().toList();
      scenarioMaps.add({
        'name': sc.name,
        'keywordJson': jsonEncode(sc.keyword),
        'descriptionJson': jsonEncode(sc.description),
        'line': sc.line,
        'hasTags': scTagsUnique.isNotEmpty,
        'tagsString': '[${scTagsUnique.map((e) => "'$e'").join(', ')}]',
        'steps': sc.steps.map((s) => {'json': s.toString()}).toList(),
        'isLast': i == feature.scenarios.length - 1,
      });
    }

    // Deduplicate tags
    final featureTagsUnique = feature.tags.toSet().toList();
    final featureData = {
      'name': feature.name,
      'descriptionJson': jsonEncode(feature.description),
      'uri': feature.uri,
      'line': feature.line,
      'hasTags': featureTagsUnique.isNotEmpty,
      'tagsString': '[${featureTagsUnique.map((e) => "'$e'").join(', ')}]',
      'scenarios': scenarioMaps,
      'backgroundSteps':
          feature.background?.steps
              .map((s) => {'jsonStep': s.toString()})
              .toList() ??
          [],
      'hasBackgroundSteps': feature.background?.steps.isNotEmpty ?? false,
    };

    final runnerDir = Directory(p.join(generatedRoot.path, p.dirname(relPath)));
    runnerDir.createSync(recursive: true);

    final configImportPath = p.relative(
      p.join(options.cwd, 'integration_test', options.configPath),
      from: runnerDir.path,
    );

    final rendered = template.renderString({
      'features': [featureData],
      'configImport': "import '$configImportPath';",
    });

    final outFilePath = p.join(
      generatedRoot.path,
      '${p.withoutExtension(relPath)}.dart',
    );

    File(outFilePath)
      ..createSync(recursive: true)
      ..writeAsStringSync(rendered);

    generatedCount++;
    stdout.writeln('Generated $outFilePath');
  }

  final genDir = Directory(
    p.join(options.cwd, 'integration_test', 'generated'),
  );
  List<File> allFiles =
      genDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();

  switch (options.order) {
    case 'alphabetically':
      allFiles.sort((a, b) => a.path.compareTo(b.path));
      break;
    case 'basename':
      allFiles.sort((a, b) {
        final na = p.basenameWithoutExtension(a.path);
        final nb = p.basenameWithoutExtension(b.path);
        return na.compareTo(nb);
      });
      break;
    case var s when s.startsWith('random'):
      final parts = options.order.split(':');
      final rng =
          (parts.length == 2 && int.tryParse(parts[1]) != null)
              ? Random(int.parse(parts[1]))
              : Random();
      allFiles.shuffle(rng);
      break;
    case 'reverse':
      allFiles = allFiles.reversed.toList();
      break;
    default:
      break;
  }

  if (allFiles.isEmpty) {
    final emptyMaster = File(
      p.join(options.cwd, 'integration_test', 'all_integration_tests.dart'),
    );
    emptyMaster
      ..createSync(recursive: true)
      ..writeAsStringSync(
        '// DO NOT EDIT MANUALLY. Generated by flutter_bdd_suite.\nvoid main() {}\n',
      );

    return GeneratePipelineResult(
      generatedCount: 0,
      masterRunnerPath: p.join(
        'integration_test',
        'all_integration_tests.dart',
      ),
    );
  }

  final basenameCount = <String, int>{};
  for (final file in allFiles) {
    final base = p.basenameWithoutExtension(
      p.relative(file.path, from: 'integration_test'),
    );
    basenameCount[base] = (basenameCount[base] ?? 0) + 1;
  }

  final importLines = <String>[];
  final callLines = <String>[];
  final usedSoFar = <String, int>{};

  for (final file in allFiles) {
    final rel = p.relative(file.path, from: 'integration_test');
    final base = p.basenameWithoutExtension(rel);
    final cnt = basenameCount[base]!;
    final idx = (usedSoFar[base] ?? 0) + 1;
    usedSoFar[base] = idx;
    final alias = cnt > 1 ? '${base}_$idx' : base;
    importLines.add("import '$rel' as $alias;");
    callLines.add('  $alias.run(helper);');
  }

  final masterConfigImport =
      "import '${p.relative(p.join(options.cwd, 'integration_test', options.configPath), from: p.join(options.cwd, 'integration_test'))}';";

  final buffer =
      StringBuffer()
        ..writeln('// DO NOT EDIT MANUALLY. Generated by flutter_bdd_suite.')
        ..writeln("import 'package:flutter_bdd_suite/flutter_bdd_suite.dart';")
        ..writeln(masterConfigImport)
        ..writeln();

  for (final line in importLines) {
    buffer.writeln(line);
  }

  buffer
    ..writeln()
    ..writeln('void main() async {')
    ..writeln(
      '  final helper = await IntegrationTestHelper.create(config: config);',
    )
    ..writeln()
    ..writeln(
      '  // Register suite-level setUpAll/tearDownAll exactly once for all features.',
    )
    ..writeln(
      '  // Individual feature runners do not call registerSuiteHooks themselves.',
    )
    ..writeln('  helper.registerSuiteHooks();')
    ..writeln();

  for (final line in callLines) {
    buffer.writeln(line);
  }

  buffer.writeln('}');

  final masterFile = File(
    p.join(options.cwd, 'integration_test', 'all_integration_tests.dart'),
  );
  masterFile
    ..createSync(recursive: true)
    ..writeAsStringSync(buffer.toString());

  stdout.writeln(
    'Generated integration_test/all_integration_tests.dart with ${allFiles.length} runners.',
  );

  return GeneratePipelineResult(
    generatedCount: generatedCount,
    masterRunnerPath: p.join('integration_test', 'all_integration_tests.dart'),
  );
}
