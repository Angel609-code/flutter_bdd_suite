import 'package:flutter_bdd_suite/integration_test_config.dart';
import 'package:integration_test/integration_test.dart';

IntegrationTestWidgetsFlutterBinding? _binding;
bool _bootstrapped = false;

/// Ensure the integration binding is initialized exactly once,
/// and invoke the config callback exactly once.
///
/// This function is `async` so that [IntegrationTestConfig.onBindingInitialized]
/// is fully awaited before the caller proceeds. Forgetting to `await` this
/// function means any async setup work (e.g. channel registrations, dependency
/// injection bootstrapping) will race with the first test.
Future<void> bootstrap(IntegrationTestConfig config) async {
  if (_bootstrapped) return;

  _binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await config.onBindingInitialized?.call(_binding!);

  _bootstrapped = true;
}

IntegrationTestWidgetsFlutterBinding get binding {
  if (_binding == null) {
    throw StateError(
        'You must call bootstrap(config) before accessing binding.'
    );
  }

  return _binding!;
}
