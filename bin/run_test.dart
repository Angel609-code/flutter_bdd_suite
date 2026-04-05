import 'dart:io';
import 'dart:async';

import 'package:flutter_gherkin_parser/runner/generation_pipeline.dart';
import 'package:flutter_gherkin_parser/server/integration_test_server.dart';

Future<void> main(List<String> args) async {
  final cwd = Directory.current.path;

  final configPath = _readArg(args, '--config');
  if (configPath == null || configPath.trim().isEmpty) {
    stderr.writeln('Error: --config <file> is required');
    exitCode = 1;
    return;
  }

  final mode = (_readArg(args, '--mode') ?? 'test').toLowerCase();
  if (mode != 'test' && mode != 'drive') {
    stderr.writeln('Error: --mode must be either test or drive');
    exitCode = 1;
    return;
  }

  final order = _readArg(args, '--order') ?? 'none';
  final pattern = _readArg(args, '--pattern');
  final tags = _readArg(args, '--tags');
  final command = _readArg(args, '--command');
  final dryRun = args.contains('--dry-run');
  final coverage = args.contains('--coverage');
  final generateOnly = args.contains('--generate-only');

  final bridgeConfig = _resolveBridgeConfig(args: args);
  final forceNoBridge = args.contains('--no-bridge');
  final bridgeScriptPath = _readArg(args, '--bridge-script') ?? 'integration_test/integration_test_server.dart';
  final bridgeSetupPath = _readArg(args, '--bridge-setup') ?? 'integration_test/bridge_setup.dart';
  final bridgeMode = forceNoBridge ? 'plain' : bridgeConfig.mode;
  if (!{'plain', 'auto', 'bridge'}.contains(bridgeMode)) {
    stderr.writeln('Error: --bridge-mode must be plain, auto, or bridge');
    exitCode = 1;
    return;
  }

  final flutterArgs = _readRepeatedArg(args, '--flutter-arg');

  try {
    final result = await runGeneratePipeline(GeneratePipelineOptions(
      cwd: cwd,
      configPath: configPath,
      order: order,
      pattern: pattern,
      tags: tags,
    ));

    stdout.writeln('\nGenerated ${result.generatedCount} file(s).');

    if (result.generatedCount == 0) {
      stdout.writeln('No scenarios matched your current selection; execution skipped.');
      return;
    }

    final shouldStartBridge = await _shouldStartBridge(
      mode: bridgeMode,
      cwd: cwd,
      configPath: configPath,
      bridgeScriptPath: bridgeScriptPath,
      bridgeSetupPath: bridgeSetupPath,
    );

    if (generateOnly) {
      stdout.writeln('Generate-only mode enabled; execution skipped.');
      return;
    }

    _ManagedBridgeRuntime? runtime;
    var bridgeActive = false;
    try {
      if (shouldStartBridge) {
        try {
          runtime = await _startBridgeRuntime(
            cwd: cwd,
            bridgeScriptPath: bridgeScriptPath,
            bridgeSetupPath: bridgeSetupPath,
            bridgeConfig: bridgeConfig,
          );
          bridgeActive = true;
        } catch (error) {
          _printBridgeWarning(
            'Bridge client was not able to run: $error. Continuing test run without bridge.',
          );
        }
      }

      final commandData = _buildExecutionCommand(
        mode: mode,
        target: result.masterRunnerPath,
        args: args,
        coverage: coverage,
        flutterArgs: flutterArgs,
        commandOverride: command,
        bridgeConfig: bridgeConfig,
        includeBridgeDefines: bridgeActive,
      );

      stdout.writeln('Execution command: ${commandData.display}');
      if (dryRun) {
        stdout.writeln('Dry run enabled; command was not executed.');
        return;
      }

      final code = await _runCommand(commandData);
      exitCode = code;
    } finally {
      await runtime?.stop();
    }
  } catch (error) {
    stderr.writeln('run_test failed: $error');
    exitCode = 1;
  }
}

Future<bool> _shouldStartBridge({
  required String mode,
  required String cwd,
  required String configPath,
  required String bridgeScriptPath,
  required String bridgeSetupPath,
}) async {
  if (mode == 'bridge') {
    return true;
  }

  if (mode == 'plain') {
    return false;
  }

  final configFile = File('$cwd/integration_test/$configPath');
  final hasBridgeScript = File('$cwd/$bridgeScriptPath').existsSync();
  final hasBridgeSetup = File('$cwd/$bridgeSetupPath').existsSync();

  if (!configFile.existsSync()) {
    return hasBridgeScript || hasBridgeSetup;
  }

  final content = await configFile.readAsString();
  return _containsActiveJsonReporter(content) ||
      hasBridgeScript ||
      hasBridgeSetup;
}

bool _containsActiveJsonReporter(String rawContent) {
  final withoutBlockComments = rawContent.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
  final withoutLineComments = withoutBlockComments
      .split('\n')
      .map((line) => line.replaceFirst(RegExp(r'//.*$'), ''))
      .join('\n');

  return RegExp(r'\bJsonReporter\s*\(').hasMatch(withoutLineComments);
}

Future<_ManagedBridgeRuntime> _startBridgeRuntime({
  required String cwd,
  required String bridgeScriptPath,
  required String bridgeSetupPath,
  required _ResolvedBridgeConfig bridgeConfig,
}) async {
  await _assertPortAvailable(bridgeConfig.port);

  final bridgeScript = File('$cwd/$bridgeScriptPath');
  if (bridgeScript.existsSync()) {
    final environment = <String, String>{
      ...Platform.environment,
      'FGP_BRIDGE_PORT': '${bridgeConfig.port}',
      if (bridgeConfig.host != null) 'FGP_BRIDGE_HOST': bridgeConfig.host!,
    };

    final process = await Process.start(
      'dart',
      [bridgeScriptPath],
      workingDirectory: cwd,
      environment: environment,
      runInShell: true,
    );

    late final List<StreamSubscription<List<int>>> subscriptions;
    try {
      subscriptions = await _attachBridgeProcessSubscriptions(
        process: process,
        port: bridgeConfig.port,
      );
    } catch (_) {
      process.kill(ProcessSignal.sigkill);
      rethrow;
    }

    return _ProcessBridgeRuntime(
      process: process,
      subscriptions: subscriptions,
    );
  }

  final bridgeSetup = File('$cwd/$bridgeSetupPath');
  if (bridgeSetup.existsSync()) {
    final generated = await _writeGeneratedBridgeRunner(
      cwd: cwd,
      bridgeSetupPath: bridgeSetupPath,
    );

    final environment = <String, String>{
      ...Platform.environment,
      'FGP_BRIDGE_PORT': '${bridgeConfig.port}',
      if (bridgeConfig.host != null) 'FGP_BRIDGE_HOST': bridgeConfig.host!,
    };

    final process = await Process.start(
      'dart',
      [generated],
      workingDirectory: cwd,
      environment: environment,
      runInShell: true,
    );

    late final List<StreamSubscription<List<int>>> subscriptions;
    try {
      subscriptions = await _attachBridgeProcessSubscriptions(
        process: process,
        port: bridgeConfig.port,
      );
    } catch (_) {
      process.kill(ProcessSignal.sigkill);
      rethrow;
    }

    return _ProcessBridgeRuntime(
      process: process,
      subscriptions: subscriptions,
    );
  }

  final server = IntegrationTestServer(port: bridgeConfig.port);
  await server.start();
  return _InternalBridgeRuntime(server);
}

Future<List<StreamSubscription<List<int>>>> _attachBridgeProcessSubscriptions({
  required Process process,
  required int port,
}) async {
  final stdoutStream = process.stdout.asBroadcastStream();
  final stderrStream = process.stderr.asBroadcastStream();

  // Keep bridge process output drained silently for the whole lifecycle.
  // This avoids stdout/stderr binding conflicts while flutter commands stream output.
  final silentSubscriptions = <StreamSubscription<List<int>>>[
    stdoutStream.listen((_) {}),
    stderrStream.listen((_) {}),
  ];

  await _waitForBridgeReadiness(
    process: process,
    port: port,
  );

  return silentSubscriptions;
}

Future<void> _assertPortAvailable(int port) async {
  if (!await _isPortReachable(port)) {
    return;
  }

  throw StateError(
    'port $port is already in use',
  );
}

Future<void> _waitForBridgeReadiness({
  required Process process,
  required int port,
}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 6));

  while (DateTime.now().isBefore(deadline)) {
    final exitCode = await _tryReadExitCode(process);
    if (exitCode != null) {
      throw StateError(
        'startup process exited early (code: $exitCode)',
      );
    }

    if (await _isPortReachable(port)) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  throw StateError(
    'timeout waiting for bridge on port $port',
  );
}

Future<int?> _tryReadExitCode(Process process) async {
  final completer = Completer<int?>();

  process.exitCode.then((value) {
    if (!completer.isCompleted) {
      completer.complete(value);
    }
  });

  Future<void>.delayed(const Duration(milliseconds: 5), () {
    if (!completer.isCompleted) {
      completer.complete(null);
    }
  });

  return completer.future;
}

void _printBridgeWarning(String message) {
  const orange = '\u001b[33m';
  const reset = '\u001b[0m';
  stdout.writeln('$orange$message$reset');
}

Future<bool> _isPortReachable(int port) async {
  Socket? socket;
  try {
    socket = await Socket.connect(
      InternetAddress.loopbackIPv4,
      port,
      timeout: const Duration(milliseconds: 150),
    );
    return true;
  } catch (_) {
    return false;
  } finally {
    socket?.destroy();
  }
}

_ExecutionCommand _buildExecutionCommand({
  required String mode,
  required String target,
  required List<String> args,
  required bool coverage,
  required List<String> flutterArgs,
  required String? commandOverride,
  required _ResolvedBridgeConfig bridgeConfig,
  required bool includeBridgeDefines,
}) {
  if (commandOverride != null && commandOverride.trim().isNotEmpty) {
    if (includeBridgeDefines) {
      stdout.writeln(
        'Warning: --command mode cannot inject automatic --dart-define bridge values. '
        'Add FGP_BRIDGE_HOST/FGP_BRIDGE_PORT defines manually in your command if needed.',
      );
    }
    return _ExecutionCommand.shell(commandOverride.trim());
  }

  final bridgeDefines = <String>[
    if (includeBridgeDefines && bridgeConfig.host != null) '--dart-define=FGP_BRIDGE_HOST=${bridgeConfig.host}',
    if (includeBridgeDefines) '--dart-define=FGP_BRIDGE_PORT=${bridgeConfig.port}',
  ];

  if (mode == 'drive') {
    final driver = _readArg(args, '--driver') ?? 'test_driver/integration_test.dart';
    final device = _readArg(args, '--device') ?? 'chrome';
    final explicitTarget = _readArg(args, '--target') ?? target;

    return _ExecutionCommand.process(
      executable: 'flutter',
      arguments: [
        'drive',
        '--driver=$driver',
        '--target=$explicitTarget',
        '-d',
        device,
        ...bridgeDefines,
        ...flutterArgs,
      ],
    );
  }

  final explicitTarget = _readArg(args, '--target') ?? target;
  return _ExecutionCommand.process(
    executable: 'flutter',
    arguments: [
      'test',
      explicitTarget,
      if (coverage) '--coverage',
      ...bridgeDefines,
      ...flutterArgs,
    ],
  );
}

_ResolvedBridgeConfig _resolveBridgeConfig({
  required List<String> args,
}) {
  const defaults = _BridgeConfig(mode: 'auto', port: 9876);

  final envMode = Platform.environment['FGP_BRIDGE_MODE'];
  final envHost = Platform.environment['FGP_BRIDGE_HOST'];
  final envPort = int.tryParse(Platform.environment['FGP_BRIDGE_PORT'] ?? '');

  final cliMode = _readArg(args, '--bridge-mode');
  final cliHost = _readArg(args, '--bridge-host');
  final cliPort = int.tryParse(_readArg(args, '--bridge-port') ?? '');

  final resolvedMode = (cliMode ?? envMode ?? defaults.mode).toLowerCase();
  final resolvedHost = _firstNonEmpty(cliHost, envHost);
  final resolvedPort = cliPort ?? envPort ?? defaults.port;

  return _ResolvedBridgeConfig(
    mode: resolvedMode,
    host: resolvedHost,
    port: resolvedPort,
  );
}
String? _firstNonEmpty(String? first, String? second) {
  for (final value in [first, second]) {
    if (value != null && value.trim().isNotEmpty) {
      return value;
    }
  }

  return null;
}

Future<String> _writeGeneratedBridgeRunner({
  required String cwd,
  required String bridgeSetupPath,
}) async {
  final generatedDir = Directory('$cwd/.dart_tool/flutter_gherkin_parser');
  if (!generatedDir.existsSync()) {
    generatedDir.createSync(recursive: true);
  }

  final generatedFile = File('${generatedDir.path}/bridge_runner.dart');
  final setupImport = bridgeSetupPath.replaceAll('\\', '/');

  final content = '''// GENERATED FILE. DO NOT EDIT.
import 'package:flutter_gherkin_parser/server/integration_test_server.dart';
import '../../$setupImport';

Future<void> main() async {
  final server = IntegrationTestServer();
  await Future.sync(() => registerBridgeEndpoints(server));
  await server.start();
}
''';

  await generatedFile.writeAsString(content);
  return generatedFile.path;
}

Future<int> _runCommand(_ExecutionCommand command) async {
  if (command.isShell) {
    late final Process process;

    if (Platform.isWindows) {
      process = await Process.start('cmd', ['/c', command.shellCommand!]);
    } else {
      process = await Process.start('/bin/sh', ['-c', command.shellCommand!]);
    }

    await stdout.addStream(process.stdout);
    await stderr.addStream(process.stderr);
    return await process.exitCode;
  }

  final process = await Process.start(
    command.executable!,
    command.arguments!,
    runInShell: true,
  );

  await stdout.addStream(process.stdout);
  await stderr.addStream(process.stderr);
  return await process.exitCode;
}

String? _readArg(List<String> args, String name) {
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a.startsWith('$name=')) {
      return a.substring(name.length + 1);
    }
    if (a == name && i + 1 < args.length) {
      return args[i + 1];
    }
  }

  return null;
}

List<String> _readRepeatedArg(List<String> args, String name) {
  final values = <String>[];

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a.startsWith('$name=')) {
      values.add(a.substring(name.length + 1));
      continue;
    }

    if (a == name && i + 1 < args.length) {
      values.add(args[i + 1]);
      i++;
    }
  }

  return values;
}

class _ExecutionCommand {
  final String? executable;
  final List<String>? arguments;
  final String? shellCommand;

  const _ExecutionCommand._({
    this.executable,
    this.arguments,
    this.shellCommand,
  });

  factory _ExecutionCommand.process({
    required String executable,
    required List<String> arguments,
  }) {
    return _ExecutionCommand._(
      executable: executable,
      arguments: arguments,
    );
  }

  factory _ExecutionCommand.shell(String command) {
    return _ExecutionCommand._(shellCommand: command);
  }

  bool get isShell => shellCommand != null;

  String get display {
    if (isShell) {
      return shellCommand!;
    }

    return '$executable ${arguments!.join(' ')}';
  }
}

class _BridgeConfig {
  final String mode;
  final int port;

  const _BridgeConfig({
    required this.mode,
    required this.port,
  });
}

class _ResolvedBridgeConfig {
  final String mode;
  final String? host;
  final int port;

  const _ResolvedBridgeConfig({
    required this.mode,
    this.host,
    required this.port,
  });
}

abstract class _ManagedBridgeRuntime {
  Future<void> stop();
}

class _InternalBridgeRuntime implements _ManagedBridgeRuntime {
  final IntegrationTestServer _server;

  _InternalBridgeRuntime(this._server);

  @override
  Future<void> stop() async {
    await _server.stop();
  }
}

class _ProcessBridgeRuntime implements _ManagedBridgeRuntime {
  final Process process;
  final List<StreamSubscription<List<int>>> subscriptions;

  _ProcessBridgeRuntime({
    required this.process,
    required this.subscriptions,
  });

  @override
  Future<void> stop() async {
    if (process.exitCode case final Future<int> codeFuture) {
      final exited = await codeFuture.timeout(
        const Duration(milliseconds: 10),
        onTimeout: () => -9999,
      );
      if (exited != -9999) {
        return;
      }
    }

    for (final subscription in subscriptions) {
      await subscription.cancel();
    }

    if (process.kill(ProcessSignal.sigterm)) {
      await process.exitCode.timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          process.kill(ProcessSignal.sigkill);
          return -1;
        },
      );
    }
  }
}
