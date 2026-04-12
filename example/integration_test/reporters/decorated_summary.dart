import 'dart:math';
import 'package:flutter_bdd_suite/flutter_bdd_suite.dart';
import 'package:wcwidth/wcwidth.dart';

class DecoratedSummaryReporter extends IntegrationReporter {
  /// Matches any ANSI colour/style escape sequence so that visible width can
  /// be measured after stripping the non-printable bytes.
  static final _ansiEscapePattern = RegExp(r'\x1B\[[0-9;]*m');

  /// Total number of characters added around the content inside a box line:
  /// `║ ` (2) on the left + ` ║` (2) on the right = 4.
  static const _boxPadding = 4;

  DateTime? _startTime;
  int _totalScenarios = 0,
      _passedScenarios = 0,
      _failedScenarios = 0,
      _skippedScenarios = 0;
  ScenarioStatus? _currentStatus;

  @override
  int get priority => 0;

  @override
  Future<void> onBeforeAll() async => _startTime = DateTime.now();

  @override
  Future<void> onBeforeScenario(ScenarioInfo _) async {
    _totalScenarios++;
    _currentStatus = ScenarioStatus.passed;
  }

  @override
  Future<void> onAfterStep(AfterStepContext context) async {
    final result = context.result;
    if (result is StepFailure) {
      _currentStatus = ScenarioStatus.failed;
    } else if (result is StepSkipped &&
        _currentStatus == ScenarioStatus.passed) {
      _currentStatus = ScenarioStatus.skipped;
    }
  }

  @override
  Future<void> onAfterScenario(ScenarioResult result) async {
    switch (_currentStatus) {
      case ScenarioStatus.passed:
        _passedScenarios++;
        break;
      case ScenarioStatus.failed:
        _failedScenarios++;
        break;
      case ScenarioStatus.skipped:
        _skippedScenarios++;
        break;
      default:
        break;
    }
  }

  int _visibleWidth(String s) => s.wcwidth();

  String _buildLine(
    String label,
    String value,
    int contentWidth, {
    String? symbol,
    String? colorCode,
  }) {
    final rawValue = symbol != null ? '$symbol$value' : value;
    final colored = colorCode != null ? '$colorCode$rawValue$reset' : rawValue;
    final text = '$label : $rawValue';
    final padSize = contentWidth - _visibleWidth(text);
    final padding = padSize > 0 ? ' ' * padSize : '';
    return '║ $label : $colored$padding ║';
  }

  @override
  Future<void> onAfterAll() async {
    final elapsed = DateTime.now().difference(_startTime!);
    final mins = elapsed.inMinutes, secs = elapsed.inSeconds % 60;
    final millis = (elapsed.inMilliseconds % 1000).toString().padLeft(3, '0');

    final entries = [
      ['Total scenarios', _totalScenarios.toString(), null, null],
      ['Passed', _passedScenarios.toString(), '✓', green],
      ['Failed', _failedScenarios.toString(), '✗', red],
      ['Skipped', _skippedScenarios.toString(), '↺', yellow],
      ['Elapsed Time', '${mins}m$secs.${millis}s', null, null],
    ];

    // Determine the widest content line so that all box rows are the same width.
    final contentWidths = entries.map((e) {
      final label = e[0] as String;
      final val = e[1] as String;
      final sym = e[2];
      final raw = sym != null ? '$sym$val' : val;
      return _visibleWidth('$label : $raw');
    });
    final maxContentWidth = contentWidths.reduce(max);

    // Border row: one '═' per content character + 2 padding spaces.
    final border = '═' * (maxContentWidth + 2);

    // Header padded to fill the full content width.
    final header = 'Summary'.padRight(maxContentWidth);

    final lines = [
      '╔$border╗',
      '║ $header ║',
      '╠$border╣',
      for (var e in entries)
        _buildLine(
          e[0] as String,
          e[1] as String,
          maxContentWidth,
          symbol: e[2],
          colorCode: e[3],
        ),
      '╚$border╝',
    ];

    final expectedWidth = maxContentWidth + _boxPadding;
    for (var raw in lines) {
      final noAnsi = raw.replaceAll(_ansiEscapePattern, '');
      final actual = _visibleWidth(noAnsi);
      if (actual != expectedWidth) {
        logLine(
          'DEBUG MISMATCH: got $actual, expected $expectedWidth → "$noAnsi"',
        );
      }
    }

    logLine('');
    for (var l in lines) {
      logLine(
        l.replaceAllMapped(
          RegExp(r'^[╔╠╚║]'),
          (m) => '$cyan${m[0]}$reset',
        ),
      );
    }
    logLine(reset);
    logLine('');
  }

  @override
  Future<void> onBeforeStep(BeforeStepContext _) async {}

  @override
  Future<void> onBeforeFeature(FeatureInfo _) async {}

  @override
  Future<void> onAfterFeature(FeatureInfo _) async {}

  @override
  Map<String, dynamic> toJson() => {};
}
