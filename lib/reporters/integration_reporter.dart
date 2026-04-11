import 'package:flutter_bdd_suite/lifecycle_listener.dart';

abstract class IntegrationReporter implements LifecycleListener {
  final String path;
  IntegrationReporter({this.path = ''});

  @override
  String? get tagExpression => null;

  Map<String, dynamic> toJson();
}
