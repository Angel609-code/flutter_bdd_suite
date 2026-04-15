import 'package:flutter_bdd_suite/src/models/report_presentation.dart';
import 'package:flutter_bdd_suite/src/models/gherkin_table_model.dart';
import 'package:flutter_bdd_suite/src/steps/step_result.dart';
import 'package:flutter_bdd_suite/src/utils/terminal_colors.dart' as colors;

/// Handles the visual representation of Gherkin execution data.
class CucumberFormatter {
  /// Creates a new [CucumberFormatter] with the given [presentation].
  CucumberFormatter(this.presentation);

  /// The presentation settings for the report.
  final ReportPresentation presentation;

  String get _green => presentation.useColors ? colors.green : '';
  String get _red => presentation.useColors ? colors.red : '';
  String get _yellow => presentation.useColors ? colors.yellow : '';
  String get _cyan => presentation.useColors ? colors.cyan : '';
  String get _gray => presentation.useColors ? colors.gray : '';
  String get _reset => presentation.useColors ? colors.reset : '';

  /// Formats a feature header.
  String formatFeature(String name) => 'Feature: $name';

  /// Formats a scenario header.
  String formatScenario(String name) => '  Scenario: $name';

  /// Formats a single step execution result.
  String formatStep(StepResult result, {String? uri}) {
    final symbol = _getSymbol(result.status);
    final color = _getColor(result.status);

    // Paths are shown if globally enabled OR if the step failed.
    final showPath =
        presentation.showStepPaths ||
        result.status == StepStatus.failure ||
        result.status == StepStatus.ambiguous;

    final pathStr =
        (showPath && uri != null) ? ' $_gray[$uri:${result.line}]$_reset' : '';

    return '    $color$symbol ${result.stepText}$pathStr$_reset';
  }

  /// Formats an attached doc-string or data table for pretty console output.
  List<String> formatMultilineArgument(StepResult result) {
    if (result.docString != null) {
      return _formatDocString(result.docString!);
    }

    if (result.table != null) {
      return _formatTable(result.table!);
    }

    return const [];
  }

  /// Formats a clean error message for a failed step.
  String? formatError(StepResult result) {
    if (result is StepFailure) {
      final cleanError = _cleanError(result.error.toString());
      return '      $_red   Error: $cleanError$_reset';
    }
    if (result is StepAmbiguous) {
      final cleanError = _cleanError(result.error.toString());
      return '      $_red   Error: $cleanError$_reset';
    }
    if (result.status == StepStatus.undefined) {
      return '      ${_yellow}Step undefined. Register it in your config.$_reset';
    }
    if (result.status == StepStatus.pending) {
      return '      ${_yellow}Step pending.$_reset';
    }
    return null;
  }

  String _cleanError(String error) {
    return error
        .replaceFirst(RegExp(r'^(Exception|TestFailure):\s*'), '')
        .trim();
  }

  /// Formats a stack trace if allowed by presentation settings.
  List<String> formatStackTrace(StackTrace stackTrace) {
    if (!presentation.showStackTraces) {
      return const [];
    }

    final lines = stackTrace.toString().split('\n');
    return [
      '      ${_red}Stack trace:$_reset',
      ...lines.where((l) => l.isNotEmpty).map((l) => '        $l'),
    ];
  }

  /// Formats the summary header.
  String formatSummaryHeader() => '$_cyan[Summary]$_reset';

  /// Formats total counts of features, scenarios, and steps.
  String formatCount(int count, String label, {String? details}) {
    final pluralized = count == 1 ? '$count $label' : '$count ${label}s';
    return details != null ? '$pluralized ($details)' : pluralized;
  }

  /// Formats a duration string.
  String formatDuration(Duration elapsed) {
    final mins = elapsed.inMinutes;
    final secs = elapsed.inSeconds % 60;
    final millis = (elapsed.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '${mins}m$secs.${millis}s';
  }

  List<String> _formatDocString(String docString) {
    final lines = docString.split('\n');
    return [
      '      $_gray"""$_reset',
      ...lines.map((line) => '      $line'),
      '      $_gray"""$_reset',
    ];
  }

  List<String> _formatTable(GherkinTable table) {
    final rows = <TableRow>[
      if (table.header != null) table.header!,
      ...table.rows,
    ];

    if (rows.isEmpty) {
      return const [];
    }

    final columnCount = rows
        .map((row) => row.columns.length)
        .fold<int>(0, (max, length) => length > max ? length : max);
    final widths = List<int>.generate(columnCount, (index) {
      return rows.fold<int>(0, (max, row) {
        final value = index < row.columns.length ? row.columns[index] ?? '' : '';
        return value.length > max ? value.length : max;
      });
    });

    return rows.map((row) => _formatTableRow(row, widths)).toList();
  }

  String _formatTableRow(TableRow row, List<int> widths) {
    final cells = List<String>.generate(widths.length, (index) {
      final value = index < row.columns.length ? row.columns[index] ?? '' : '';
      return value.padRight(widths[index]);
    });

    return '      | ${cells.join(' | ')} |';
  }

  /// Formats count details (passed/failed/skipped) with colors.
  String formatDetails({
    required int passed,
    required int failed,
    required int skipped,
  }) {
    final parts = [
      if (passed > 0) '$_green$passed passed$_reset',
      if (failed > 0) '$_red$failed failed$_reset',
      if (skipped > 0) '$_yellow$skipped skipped$_reset',
    ];
    return parts.join(', ');
  }

  String _getSymbol(StepStatus status) {
    return switch (status) {
      StepStatus.success => '✓',
      StepStatus.failure || StepStatus.ambiguous => '✗',
      StepStatus.skipped => '-',
      StepStatus.undefined || StepStatus.pending => '?',
    };
  }

  String _getColor(StepStatus status) {
    return switch (status) {
      StepStatus.success => _green,
      StepStatus.failure || StepStatus.ambiguous => _red,
      StepStatus.skipped ||
      StepStatus.undefined ||
      StepStatus.pending => _yellow,
    };
  }
}
