import 'package:flutter_bdd_suite/models/models.dart';
import 'package:flutter_bdd_suite/utils/steps_keywords.dart';
import 'package:flutter_bdd_suite/utils/gherkin_keywords.dart';

class FeatureParser {
  Feature parse(String content, String featurePath) {
    final rawLines = content.split('\n');
    Feature? feature;
    Scenario? currentScenario;
    Scenario? currentOutline;
    List<String> pendingTags = [];
    bool inBackground = false;

    // Rule support
    bool inRule = false;
    Background? currentRuleBackground;

    for (int i = 0; i < rawLines.length; i++) {
      final rawLine = rawLines[i];
      final line = rawLine.trim();

      // Skip comments or empty lines
      if (line.isEmpty || line.startsWith('#')) {
        continue;
      }

      // Collect tags
      if (line.startsWith('@')) {
        final tagsInLine = line
            .split(RegExp(r'\s+'))
            .where((t) => t.startsWith('@'))
            .toList();
        pendingTags.addAll(tagsInLine);
        continue;
      }

      // Feature declaration
      if (line.startsWith(GherkinKeywords.feature)) {
        feature = Feature(
          name: line.substring(GherkinKeywords.feature.length).trim(),
          uri: '/features/$featurePath',
          line: i + 1,
          tags: pendingTags,
        );

        pendingTags = [];
        inBackground = false;
        continue;
      }

      // Rule start
      if (line.startsWith(GherkinKeywords.rule)) {
        inRule = true;
        currentRuleBackground = null;
        inBackground = false;
        currentScenario = null;
        currentOutline = null;
        pendingTags = [];
        continue;
      }

      // Background start
      if (line.startsWith(GherkinKeywords.background)) {
        // Start collecting background steps
        inBackground = true;
        if (inRule) {
          currentRuleBackground = Background();
        } else {
          feature?.background = Background();
        }
        continue;
      }

      if (line.startsWith(GherkinKeywords.scenarioOutline) || line.startsWith(GherkinKeywords.scenarioTemplate)) {
        inBackground = false;
        currentScenario = null;
        final prefix = line.startsWith(GherkinKeywords.scenarioOutline) ? GherkinKeywords.scenarioOutline : GherkinKeywords.scenarioTemplate;
        currentOutline = Scenario(
          name: line.substring(prefix.length).trim(),
          line: i + 1,
          tags: pendingTags,
        );
        pendingTags = [];
        continue;
      }

      if (line.startsWith(GherkinKeywords.examples) || line.startsWith(GherkinKeywords.scenarios)) {
        inBackground = false;
        if (currentOutline == null) {
          throw Exception('Examples block without a preceding Scenario Outline/Template');
        }

        final outlineTags = currentOutline.tags;
        final examplesTags = pendingTags;
        pendingTags = [];

        // Next lines should be a data table
        int j = i + 1;
        while (j < rawLines.length) {
          final l = rawLines[j].trim();
          if (l.isEmpty || l.startsWith('#') || l.startsWith('@')) {
            j++;
            continue;
          }
          if (GherkinKeywords.tableRowRegex.hasMatch(l)) {
            break;
          }
          break; // Stop looking for the table if a non-comment, non-empty, non-tag, non-table line is found.
        }

        if (j < rawLines.length && GherkinKeywords.tableRowRegex.hasMatch(rawLines[j].trim())) {
          // Found the data table.
          final rows = <TableRow>[];
          while (j < rawLines.length && GherkinKeywords.tableRowRegex.hasMatch(rawLines[j].trim())) {
            final tableLine = rawLines[j].trim();
            final cells = _splitTableRow(tableLine);
            rows.add(TableRow(cells));
            j++;
          }

          if (rows.length > 1) {
            final header = rows.first;
            final dataRows = rows.sublist(1);
            final keys = header.columns.map((c) => c ?? '').toList();

            for (var rIdx = 0; rIdx < dataRows.length; rIdx++) {
              final row = dataRows[rIdx];
              final substitutedScenario = Scenario(
                name: '${currentOutline.name} (Example ${rIdx + 1})',
                line: currentOutline.line,
                tags: [...outlineTags, ...examplesTags],
              );

              // If we are in a rule, prepend the rule background steps to the scenario steps.
              // We duplicate the steps so they become part of the scenario itself.
              if (inRule && currentRuleBackground != null) {
                for (final bgStep in currentRuleBackground.steps) {
                  substitutedScenario.steps.add(Step(
                    text: bgStep.text,
                    line: bgStep.line,
                  ));
                }
              }

              for (final step in currentOutline.steps) {
                String substitutedText = step.text;
                for (var colIdx = 0; colIdx < keys.length; colIdx++) {
                  final key = keys[colIdx];
                  final val = (colIdx < row.columns.length) ? row.columns[colIdx] : '';
                  substitutedText = substitutedText.replaceAll('<$key>', val ?? '');
                }
                substitutedScenario.steps.add(Step(
                  text: substitutedText,
                  line: step.line,
                ));
              }
              feature?.scenarios.add(substitutedScenario);
            }
          }
          // Fast-forward i past the consumed table
          i = j - 1;
        }
        continue;
      }

      if (line.startsWith(GherkinKeywords.scenario) || line.startsWith(GherkinKeywords.example)) {
        // Stop background collection once a scenario begins
        inBackground = false;
        currentOutline = null;
        final prefix = line.startsWith(GherkinKeywords.scenario) ? GherkinKeywords.scenario : GherkinKeywords.example;
        currentScenario = Scenario(
          name: line.substring(prefix.length).trim(),
          line: i + 1,
          tags: pendingTags,
        );

        // If we are in a rule, prepend the rule background steps to the scenario steps.
        if (inRule && currentRuleBackground != null) {
          for (final bgStep in currentRuleBackground.steps) {
            currentScenario.steps.add(Step(
              text: bgStep.text,
              line: bgStep.line,
            ));
          }
        }

        feature?.scenarios.add(currentScenario);
        pendingTags = [];
        continue;
      }

      // Skip pure “table row” lines—they will be consumed below, not treated as separate steps
      if (GherkinKeywords.tableRowRegex.hasMatch(rawLine)) {
        continue;
      }

      // If it matches a stepLinePattern, create a Step
      if (stepLinePattern.hasMatch(line)) {
        // By default, stepText is just “line”
        String stepText = line;

        // Check for Doc Strings
        if (i + 1 < rawLines.length) {
          final nextLineTrimmed = rawLines[i + 1].trim();
          if (nextLineTrimmed.startsWith(GherkinKeywords.docStringTripleQuote) || nextLineTrimmed.startsWith(GherkinKeywords.docStringBackticks)) {
            final docStringDelimiter = nextLineTrimmed.substring(0, 3);
            i++; // skip the opening delimiter line
            final docStringLines = <String>[];
            while (i + 1 < rawLines.length) {
              i++;
              final l = rawLines[i];
              if (l.trim().startsWith(docStringDelimiter)) {
                break;
              }
              docStringLines.add(l);
            }
            final docStringContent = docStringLines.join('\n');
            // We serialize Doc Strings with <<<DOCSTRING:content>>> marker.
            // Escape any quotes or special chars inside JSON encode or just use raw content?
            // Actually, we can just dump it inside the stepText like we do JSON.
            // But we need to make sure we don't break JSON generation.
            // Let's just encode the docstring as JSON string to be safe.
            stepText = '$stepText "${GherkinKeywords.docStringMarker}${docStringContent.replaceAll('"', r'\"').replaceAll('\n', r'\n')}>>>"';
          }
        }

        // Check if the next line(s) form a Gherkin table
        if (i + 1 < rawLines.length && GherkinKeywords.tableRowRegex.hasMatch(rawLines[i + 1])) {
          final rows = <TableRow>[];

          // Consume all consecutive tableRowRegex lines
          while (i + 1 < rawLines.length && GherkinKeywords.tableRowRegex.hasMatch(rawLines[i + 1])) {
            i++;
            final tableLine = rawLines[i].trim();
            final cells = _splitTableRow(tableLine);
            rows.add(TableRow(cells));
          }

          // Determine header vs data rows
          TableRow? header;
          Iterable<TableRow> dataRows;

          if (rows.length > 1) {
            header = rows.first;
            dataRows = rows.sublist(1);
          } else {
            header = null;
            dataRows = rows;
          }

          final table = GherkinTable(dataRows.toList(), header);

          // Serialize to JSON and append to stepText with a unique delimiter
          final tableJson = table.toJson();
          // Use “<<<JSON>>>” as a marker. We guarantee that no normal step text will contain “<<<” or “>>>”.
          stepText = '$stepText "<<<$tableJson>>>"';
        }

        // Now create the Step with the combined text
        final step = Step(
          text: stepText,
          line: i + 1,
        );

        if (inBackground) {
          if (inRule && currentRuleBackground != null) {
            currentRuleBackground.steps.add(step);
          } else {
            feature?.background?.steps.add(step);
          }
        } else if (currentOutline != null) {
          currentOutline.steps.add(step);
        } else {
          currentScenario?.steps.add(step);
        }
      }
    }

    if (feature == null) {
      throw Exception('No feature found in file.');
    }

    return feature;
  }

  List<String?> _splitTableRow(String rowString) {
    // Strip leading and trailing pipe
    var content = rowString.trim();
    if (content.startsWith('|')) {
      content = content.substring(1);
    }
    if (content.endsWith('|')) {
      content = content.substring(0, content.length - 1);
    }

    final cells = <String?>[];
    var currentCell = StringBuffer();
    bool escaped = false;

    for (var i = 0; i < content.length; i++) {
      final char = content[i];

      if (escaped) {
        if (char == 'n') {
          currentCell.write('\n');
        } else if (char == '|') {
          currentCell.write('|');
        } else if (char == '\\') {
          currentCell.write('\\');
        } else {
          // If it's an unrecognized escape, just write both slash and char
          currentCell.write('\\$char');
        }
        escaped = false;
      } else {
        if (char == '\\') {
          escaped = true;
        } else if (char == '|') {
          final val = currentCell.toString().trim();
          cells.add(val.isEmpty ? null : val);
          currentCell.clear();
        } else {
          currentCell.write(char);
        }
      }
    }

    final lastVal = currentCell.toString().trim();
    cells.add(lastVal.isEmpty ? null : lastVal);

    return cells;
  }
}
