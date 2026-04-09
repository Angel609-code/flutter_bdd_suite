/// Associates a regex fragment with a parser function for a placeholder token.
///
/// Each placeholder is identified by a name such as `string` or `int`. The
/// `regexPart` defines how to capture the relevant content from the step text.
/// The `parser` function transforms that captured raw value into the target
/// type (for example, converting a string to an `int`).
///
/// Data tables and doc-strings are **no longer placeholder tokens**. They are
/// first-class properties on [Step] and are forwarded to step functions as
/// named arguments (`table:` and `docString:`). See [StepDefinitionGeneric]
/// for details.
class PlaceholderDef {
  /// Fragment of a regular expression that captures the placeholder's content.
  ///
  /// For instance, `r'"(.*?)"'` captures any characters inside double quotes.
  final String regexPart;

  /// Function that converts the captured raw string into the desired type.
  ///
  /// Called with the text matched by [regexPart] (without outer quotes where
  /// applicable) to produce the strongly-typed argument passed to the step
  /// implementation.
  final dynamic Function(String) parser;

  const PlaceholderDef({
    required this.regexPart,
    required this.parser,
  });
}

/// Defines which placeholder tokens are supported and how to handle them.
///
/// The key is the placeholder name (without braces), e.g. `'string'`.
/// Each entry specifies a regex fragment and a parser function. To support a
/// new token, add its name as a key with the appropriate [PlaceholderDef].
///
/// **Removed tokens:**
/// - The former `table` token has been removed. Data tables are no longer
///   matched as regex placeholders. They are first-class properties on the
///   [Step] model and are delivered to step functions via the named `multilineArg:`
///   parameter on [StepFunction]. Use the unified [generic] or [genericN]
///   builders to receive them in your step implementation.
final Map<String, PlaceholderDef> placeholders = {
  'string': PlaceholderDef(
    /// Matches any sequence of characters (non-greedy) between double quotes.
    regexPart: r'"(.*?)"',

    /// Returns the exact text captured between the quotes.
    parser: (raw) => raw,
  ),
  'int': PlaceholderDef(
    /// Matches an optional leading minus sign followed by one or more digits.
    regexPart: r'(-?\d+)',

    /// Parses the captured string to a Dart [int].
    parser: (raw) => int.parse(raw),
  ),
  'float': PlaceholderDef(
    /// Matches an optional leading minus sign, digits, an optional decimal
    /// point and fractional digits, covering both integers and decimals.
    regexPart: r'(-?\d+(?:\.\d+)?)',

    /// Parses the captured string to a Dart [double].
    parser: (raw) => double.parse(raw),
  ),
  'word': PlaceholderDef(
    /// Matches one or more non-whitespace characters — a single word.
    regexPart: r'(\S+)',

    /// Returns the captured word as-is.
    parser: (raw) => raw,
  ),
};
