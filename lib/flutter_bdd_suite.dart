/// Public API for the `flutter_bdd_suite` package.
///
/// Import this library when you want a single entry point for the most common
/// BDD runner types: configuration, runner bootstrap, step builders,
/// models, hooks, and reporters.
library;

export 'src/bootstrap.dart';
export 'src/integration_test_config.dart';
export 'src/integration_test_helper.dart';
export 'src/lifecycle_listener.dart';
export 'src/lifecycle_manager.dart';
export 'src/logger.dart';

export 'src/hooks/integration_hook.dart';

export 'src/models/models.dart';
export 'src/models/step_hook_contexts.dart';
export 'src/models/integration_server_result_model.dart';
export 'src/models/endpoint_registration_model.dart';

export 'src/reporters/integration_reporter.dart';
export 'src/reporters/json_reporter.dart';
export 'src/reporters/summary_reporter.dart';

export 'src/server/bridge_client.dart';
export 'src/server/integration_endpoints.dart';
export 'src/server/integration_test_server.dart' hide EndpointHandler;

export 'src/steps/step_exceptions.dart';
export 'src/steps/step_result.dart';
export 'src/steps/steps_registry.dart';
export 'src/steps/when_fill_field_step.dart';

export 'src/utils/placeholders.dart';
export 'src/utils/step_args.dart';
export 'src/utils/step_definition_generic.dart';
export 'src/utils/terminal_colors.dart';
export 'src/utils/enums.dart';

export 'src/world/test_world.dart';
export 'src/world/widget_tester_world.dart';
