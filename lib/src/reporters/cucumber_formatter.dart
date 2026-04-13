import 'package:flutter_bdd_suite/src/models/report_presentation.dart';
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
