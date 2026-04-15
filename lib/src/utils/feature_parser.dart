import 'package:flutter_bdd_suite/src/models/models.dart';
import 'package:flutter_bdd_suite/src/utils/steps_keywords.dart';
import 'package:flutter_bdd_suite/src/utils/gherkin_keywords.dart';

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
        final tagsInLine =
            line.split(RegExp(r'\s+')).where((t) => t.startsWith('@')).toList();
        pendingTags.addAll(tagsInLine);
        continue;
      }

      // Feature declaration
      if (line.startsWith(GherkinKeywords.feature)) {
        final descriptionLines = _readDescriptionLines(rawLines, i + 1);
        feature = Feature(
          name: line.substring(GherkinKeywords.feature.length).trim(),
          description: descriptionLines.join('\n'),
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

      if (line.startsWith(GherkinKeywords.scenarioOutline) ||
          line.startsWith(GherkinKeywords.scenarioTemplate)) {
        inBackground = false;
        currentScenario = null;
        final prefix =
            line.startsWith(GherkinKeywords.scenarioOutline)
                ? GherkinKeywords.scenarioOutline
                : GherkinKeywords.scenarioTemplate;
        currentOutline = Scenario(
          name: line.substring(prefix.length).trim(),
          keyword: 'Scenario Outline',
          description: _readDescriptionLines(rawLines, i + 1).join('\n'),
          line: i + 1,
          tags: pendingTags,
        );
        pendingTags = [];
        continue;
      }

      if (line.startsWith(GherkinKeywords.examples) ||
          line.startsWith(GherkinKeywords.scenarios)) {
        inBackground = false;
        if (currentOutline == null) {
          throw Exception(
            'Examples block without a preceding Scenario Outline/Template',
          );
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

        if (j < rawLines.length &&
            GherkinKeywords.tableRowRegex.hasMatch(rawLines[j].trim())) {
          // Found the data table.
          final rows = <TableRow>[];
          final rowLines = <int>[];
          while (j < rawLines.length &&
              GherkinKeywords.tableRowRegex.hasMatch(rawLines[j].trim())) {
            final tableLine = rawLines[j].trim();
            final cells = _splitTableRow(tableLine);
            rows.add(TableRow(cells));
            rowLines.add(j + 1);
            j++;
          }

          if (rows.length > 1) {
            final header = rows.first;
            final dataRows = rows.sublist(1);
            final dataRowLines = rowLines.sublist(1);
            final keys = header.columns.map((c) => c ?? '').toList();

            for (var rIdx = 0; rIdx < dataRows.length; rIdx++) {
              final row = dataRows[rIdx];
              final substitutedScenario = Scenario(
                name: currentOutline.name,
                keyword: currentOutline.keyword,
                description: currentOutline.description,
                line: dataRowLines[rIdx],
                tags: [...outlineTags, ...examplesTags],
              );

              // If we are in a rule, prepend the rule background steps to the scenario steps.
              // We duplicate the steps so they become part of the scenario itself.
              if (inRule && currentRuleBackground != null) {
                for (final bgStep in currentRuleBackground.steps) {
                  substitutedScenario.steps.add(
                    Step(
                      text: bgStep.text,
                      line: bgStep.line,
                      table: bgStep.table,
                      docString: bgStep.docString,
                    ),
                  );
                }
              }

              for (final step in currentOutline.steps) {
                String substitutedText = step.text;
                for (var colIdx = 0; colIdx < keys.length; colIdx++) {
                  final key = keys[colIdx];
                  final val =
                      (colIdx < row.columns.length) ? row.columns[colIdx] : '';
                  substitutedText = substitutedText.replaceAll(
                    '<$key>',
                    val ?? '',
                  );
                }
                substitutedScenario.steps.add(
                  Step(
                    text: substitutedText,
                    line: step.line,
                    // Tables and doc-strings on outline steps are preserved as-is.
                    table: step.table,
                    docString: step.docString,
                  ),
                );
              }
              feature?.scenarios.add(substitutedScenario);
            }
          }
          // Fast-forward i past the consumed table
          i = j - 1;
        }
        continue;
      }

      if (line.startsWith(GherkinKeywords.scenario) ||
          line.startsWith(GherkinKeywords.example)) {
        // Stop background collection once a scenario begins
        inBackground = false;
        currentOutline = null;
        final prefix =
            line.startsWith(GherkinKeywords.scenario)
                ? GherkinKeywords.scenario
                : GherkinKeywords.example;
        currentScenario = Scenario(
          name: line.substring(prefix.length).trim(),
          keyword: line.startsWith(GherkinKeywords.example) ? 'Example' : 'Scenario',
          description: _readDescriptionLines(rawLines, i + 1).join('\n'),
          line: i + 1,
          tags: pendingTags,
        );

        // If we are in a rule, prepend the rule background steps to the scenario steps.
        if (inRule && currentRuleBackground != null) {
          for (final bgStep in currentRuleBackground.steps) {
            currentScenario.steps.add(
              Step(
                text: bgStep.text,
                line: bgStep.line,
                table: bgStep.table,
                docString: bgStep.docString,
              ),
            );
          }
        }

        feature?.scenarios.add(currentScenario);
        pendingTags = [];
        continue;
      }

      // Skip pure "table row" lines—they will be consumed below, not treated as separate steps
      if (GherkinKeywords.tableRowRegex.hasMatch(rawLine)) {
        continue;
      }

      // If it matches a stepLinePattern, create a Step
      if (stepLinePattern.hasMatch(line)) {
        final stepLine = i + 1;
        // stepText is the bare keyword + description.
        final String stepText = line;

        // Accumulated doc-string and table for this step — set at most once each.
        String? docString;
        GherkinTable? table;

        // ── Doc-string detection ──────────────────────────────────────────────
        // A doc-string opens with `"""` or ` ``` ` on the very next non-blank
        // line. Its content is stored verbatim in [docString]; it is never
        // appended to [stepText].
        if (i + 1 < rawLines.length) {
          final nextLineTrimmed = rawLines[i + 1].trim();
          if (nextLineTrimmed.startsWith(
                GherkinKeywords.docStringTripleQuote,
              ) ||
              nextLineTrimmed.startsWith(GherkinKeywords.docStringBackticks)) {
            final delimiter = nextLineTrimmed.substring(0, 3);
            final indentToStrip = _leadingWhitespaceWidth(rawLines[i + 1]);
            i++; // skip the opening delimiter line
            final docLines = <String>[];
            while (i + 1 < rawLines.length) {
              i++;
              final l = rawLines[i];
              if (l.trim().startsWith(delimiter)) break;
              docLines.add(_stripIndent(l, indentToStrip));
            }
            docString = docLines.join('\n');
          }
        }

        // ── Gherkin data-table detection ──────────────────────────────────────
        // A table immediately follows the step line (after any doc-string has
        // been consumed above). Its parsed form is stored in [table]; it is
        // never serialised into [stepText].
        if (i + 1 < rawLines.length &&
            GherkinKeywords.tableRowRegex.hasMatch(rawLines[i + 1])) {
          final rows = <TableRow>[];

          // Consume all consecutive table-row lines.
          while (i + 1 < rawLines.length &&
              GherkinKeywords.tableRowRegex.hasMatch(rawLines[i + 1])) {
            i++;
            final tableLine = rawLines[i].trim();
            final cells = _splitTableRow(tableLine);
            rows.add(TableRow(cells));
          }

          // Determine header vs data rows.
          TableRow? header;
          Iterable<TableRow> dataRows;

          if (rows.length > 1) {
            header = rows.first;
            dataRows = rows.sublist(1);
          } else {
            header = null;
            dataRows = rows;
          }

          table = GherkinTable(dataRows.toList(), header);
        }

        // Build the Step with table and docString as first-class properties.
        final step = Step(
          text: stepText,
          line: stepLine,
          table: table,
          docString: docString,
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

  List<String> _readDescriptionLines(List<String> rawLines, int startIndex) {
    final descriptionLines = <String>[];

    for (var i = startIndex; i < rawLines.length; i++) {
      final rawLine = rawLines[i];
      final trimmed = rawLine.trim();

      if (_isDescriptionTerminator(trimmed)) {
        break;
      }

      if (trimmed.startsWith('#')) {
        continue;
      }

      descriptionLines.add(rawLine.replaceFirst(RegExp(r'\s+$'), ''));
    }

    while (descriptionLines.isNotEmpty && descriptionLines.last.trim().isEmpty) {
      descriptionLines.removeLast();
    }

    return descriptionLines;
  }

  bool _isDescriptionTerminator(String line) {
    if (line.startsWith('@')) {
      return true;
    }

    return line.startsWith(GherkinKeywords.feature) ||
        line.startsWith(GherkinKeywords.rule) ||
        line.startsWith(GherkinKeywords.background) ||
        line.startsWith(GherkinKeywords.scenario) ||
        line.startsWith(GherkinKeywords.scenarioOutline) ||
        line.startsWith(GherkinKeywords.scenarioTemplate) ||
        line.startsWith(GherkinKeywords.example) ||
        line.startsWith(GherkinKeywords.examples) ||
        line.startsWith(GherkinKeywords.scenarios) ||
        stepLinePattern.hasMatch(line) ||
        GherkinKeywords.tableRowRegex.hasMatch(line);
  }

  int _leadingWhitespaceWidth(String line) {
    var count = 0;
    while (count < line.length) {
      final char = line[count];
      if (char != ' ' && char != '\t') {
        break;
      }
      count++;
    }
    return count;
  }

  String _stripIndent(String line, int indentToStrip) {
    if (line.trim().isEmpty) {
      return '';
    }

    var stripped = 0;
    while (stripped < line.length && stripped < indentToStrip) {
      final char = line[stripped];
      if (char != ' ' && char != '\t') {
        break;
      }
      stripped++;
    }

    return line.substring(stripped);
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
