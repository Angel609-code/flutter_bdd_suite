/// A strongly-typed wrapper around step arguments.
///
/// Use the [one], [two], [three], etc., helpers to safely extract and type-cast
/// parameters using Dart 3 records.
class StepArgs {
  final List<dynamic> _values;
  final String debugSource;

  StepArgs(this._values, {required this.debugSource});

  /// The number of arguments captured in this step.
  int get length => _values.length;

  /// Retrieves the argument at [index], ensuring it is of type [T].
  ///
  /// Throws a [RangeError] if the index is invalid.
  /// Throws a [StateError] if the actual value cannot be cast to [T].
  T at<T>(int index) {
    if (index < 0 || index >= _values.length) {
      throw RangeError(
        'StepArgs index \$index out of range (len=\$length). \$debugSource',
      );
    }
    final v = _values[index];
    if (v is T) return v;

    throw StateError(
      'Step arg \$index has type \${v.runtimeType} but expected \$T.\\n'
      'Value = \$v.\\n'
      'Source = \$debugSource',
    );
  }

  /// Extracts exactly 1 argument as a tuple.
  (T1,) one<T1>() => (at<T1>(0),);

  /// Extracts exactly 2 arguments as a tuple.
  (T1, T2) two<T1, T2>() => (at<T1>(0), at<T2>(1));

  /// Extracts exactly 3 arguments as a tuple.
  (T1, T2, T3) three<T1, T2, T3>() => (at<T1>(0), at<T2>(1), at<T3>(2));

  /// Extracts exactly 4 arguments as a tuple.
  (T1, T2, T3, T4) four<T1, T2, T3, T4>() => (
    at<T1>(0),
    at<T2>(1),
    at<T3>(2),
    at<T4>(3),
  );

  /// Extracts exactly 5 arguments as a tuple.
  (T1, T2, T3, T4, T5) five<T1, T2, T3, T4, T5>() => (
    at<T1>(0),
    at<T2>(1),
    at<T3>(2),
    at<T4>(3),
    at<T5>(4),
  );

  /// Extracts exactly 6 arguments as a tuple.
  (T1, T2, T3, T4, T5, T6) six<T1, T2, T3, T4, T5, T6>() => (
    at<T1>(0),
    at<T2>(1),
    at<T3>(2),
    at<T4>(3),
    at<T5>(4),
    at<T6>(5),
  );
}
