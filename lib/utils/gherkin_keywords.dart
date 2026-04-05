/// Contains standard Gherkin keywords and related regular expressions
/// used across the parser and generators.
library;

class GherkinKeywords {
  static const String feature = 'Feature:';
  static const String rule = 'Rule:';
  static const String background = 'Background:';
  static const String scenario = 'Scenario:';
  static const String scenarioOutline = 'Scenario Outline:';
  static const String scenarioTemplate = 'Scenario Template:';
  static const String example = 'Example:';
  static const String examples = 'Examples:';
  static const String scenarios = 'Scenarios:';

  static const String docStringTripleQuote = '"""';
  static const String docStringBackticks = '```';
  static const String docStringMarker = '<<<DOCSTRING:';

  static const String jsonTableMarker = '<<<JSON>>>';

  /// Regex to detect a “pure table row” (a line that starts and ends with '|')
  static final RegExp tableRowRegex = RegExp(r'^\s*\|.*\|\s*$');
}
