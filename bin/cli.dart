import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:flutter_bdd_suite/src/runner/generation_pipeline.dart';
import 'package:flutter_bdd_suite/flutter_bdd_bridge.dart';

Future<void> main(List<String> args) async {
  final delimiterIndex = args.indexOf('--');
  final myArgs = delimiterIndex >= 0 ? args.sublist(0, delimiterIndex) : args;
  final passthroughArgs =
      delimiterIndex >= 0 ? args.sublist(delimiterIndex + 1) : <String>[];

  if (_hasHelpFlag(myArgs)) {
    _printUsage();
    return;
  }

  final cwd = Directory.current.path;

  final configPath = _readArg(myArgs, '--config');
  if (configPath == null || configPath.trim().isEmpty) {
    stderr.writeln('Error: --config <file> is required');
    exitCode = 1;
    return;
  }

  final misplacedFlutterArgs = _collectMisplacedFlutterArgs(myArgs);
  if (misplacedFlutterArgs.isNotEmpty) {
    stderr.writeln(
      'Error: Flutter command flags must be passed after "--". '
      'Move these arguments after "--": ${misplacedFlutterArgs.join(' ')}',
    );
    exitCode = 1;
    return;
  }

  final mode = (_readArg(myArgs, '--mode') ?? 'test').toLowerCase();
  if (mode != 'test' && mode != 'drive') {
    stderr.writeln('Error: --mode must be either test or drive');
    exitCode = 1;
    return;
  }

  final order = _readArg(myArgs, '--order') ?? 'none';
  final pattern = _readArg(myArgs, '--pattern');
  final tags = _readArg(myArgs, '--tags');
  final command = _readArg(myArgs, '--command');
  final dryRun = myArgs.contains('--dry-run');
  final generateOnly = myArgs.contains('--generate-only');
  final noColors = myArgs.contains('--no-colors');
  final showPaths = myArgs.contains('--show-paths');
  final showStackTraces = myArgs.contains('--show-stack-traces');

  final bridgeConfig = _resolveBridgeConfig(args: myArgs);
  final forceNoBridge = myArgs.contains('--no-bridge');
  final bridgeScriptPath =
      _readArg(myArgs, '--bridge-script') ??
      'integration_test/integration_test_server.dart';
  final bridgeSetupPath =
      _readArg(myArgs, '--bridge-setup') ??
      'integration_test/bridge_setup.dart';
  final bridgeMode = forceNoBridge ? 'plain' : bridgeConfig.mode;

  if (!{'plain', 'auto', 'bridge'}.contains(bridgeMode)) {
    stderr.writeln('Error: --bridge-mode must be plain, auto, or bridge');
    exitCode = 1;
    return;
  }

  try {
    final result = await runGeneratePipeline(
      GeneratePipelineOptions(
        cwd: cwd,
        configPath: configPath,
        order: order,
        pattern: pattern,
        tags: tags,
      ),
    );

    stdout.writeln('\nGenerated ${result.generatedCount} file(s).');

    if (result.generatedCount == 0) {
      stdout.writeln(
        'No scenarios matched your current selection; execution skipped.',
      );
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

    if (delimiterIndex >= 0 && command == null && passthroughArgs.isEmpty) {
      stderr.writeln(
        'Warning: no passthrough args were received after "--". '
        'If using multiple lines, keep "--" on the same line as the first passthrough arg or use "\\" before line breaks.',
      );
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

        if (!bridgeActive) {
          _printBridgeWarning(
            'Bridge is inactive. Reporter mirrored logs and host report endpoints will be unavailable for this run.',
          );
        }
      }

      final commandData = _buildExecutionCommand(
        mode: mode,
        testFilePath: result.masterRunnerPath,
        commandOverride: command,
        bridgeConfig: bridgeConfig,
        includeBridgeDefines: bridgeActive,
        passthroughArgs: passthroughArgs,
        noColors: noColors,
        showPaths: showPaths,
        showStackTraces: showStackTraces,
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
    stderr.writeln('cli failed: $error');
    exitCode = 1;
  }
}

_ExecutionCommand _buildExecutionCommand({
  required String mode,
  required String testFilePath,
  required String? commandOverride,
  required _ResolvedBridgeConfig bridgeConfig,
  required bool includeBridgeDefines,
  List<String> passthroughArgs = const [],
  bool noColors = false,
  bool showPaths = false,
  bool showStackTraces = false,
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

  final normalizedPassthroughArgs = _normalizePassthroughArgs(passthroughArgs);

  final bridgeDefines = <String>[
    if (includeBridgeDefines && bridgeConfig.host != null)
      '--dart-define=FGP_BRIDGE_HOST=${bridgeConfig.host}',
    if (includeBridgeDefines)
      '--dart-define=FGP_BRIDGE_PORT=${bridgeConfig.port}',
    '--dart-define=FGP_NO_COLORS=$noColors',
    '--dart-define=FGP_SHOW_PATHS=$showPaths',
    '--dart-define=FGP_SHOW_STACK_TRACES=$showStackTraces',
  ];

  if (mode == 'drive') {
    return _ExecutionCommand.process(
      executable: 'flutter',
      arguments: ['drive', ...bridgeDefines, ...normalizedPassthroughArgs],
    );
  }

  final hasExplicitTestTarget = normalizedPassthroughArgs.any(
    _looksLikeTestTarget,
  );

  return _ExecutionCommand.process(
    executable: 'flutter',
    arguments: [
      'test',
      ...bridgeDefines,
      ...normalizedPassthroughArgs,
      if (!hasExplicitTestTarget) testFilePath,
    ],
  );
}

List<String> _normalizePassthroughArgs(List<String> passthroughArgs) {
  final normalized = <String>[];

  for (final arg in passthroughArgs) {
    if (arg == '--device') {
      normalized.add('-d');
      continue;
    }

    if (arg.startsWith('--device=')) {
      normalized
        ..add('-d')
        ..add(arg.substring('--device='.length));
      continue;
    }

    normalized.add(arg);
  }

  return normalized;
}

bool _looksLikeTestTarget(String arg) {
  if (arg.startsWith('-')) {
    return false;
  }

  final normalized = arg.replaceAll('\\', '/');
  return normalized.endsWith('.dart') ||
      normalized == 'integration_test' ||
      normalized.startsWith('integration_test/') ||
      normalized == 'test' ||
      normalized.startsWith('test/');
}

List<String> _collectMisplacedFlutterArgs(List<String> args) {
  const blocked = <String>{
    '--coverage',
    '--device',
    '-d',
    '--target',
    '--driver',
    '--flutter-arg',
    '--web-renderer',
    '--dart-define',
  };

  final found = <String>[];
  for (final arg in args) {
    if (blocked.contains(arg)) {
      found.add(arg);
      continue;
    }

    for (final flag in blocked) {
      if (arg.startsWith('$flag=')) {
        found.add(arg);
        break;
      }
    }
  }

  return found;
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
  final withoutBlockComments = rawContent.replaceAll(
    RegExp(r'/\*[\s\S]*?\*/'),
    '',
  );
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
      runInShell: Platform.isWindows,
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
      runInShell: Platform.isWindows,
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

  // Keep bridge process output drained and forwarded for the whole lifecycle.
  // This makes bridge-side logs visible even when flutter drive suppresses app stdout.
  final silentSubscriptions = <StreamSubscription<List<int>>>[
    stdoutStream.listen((data) {
      final text = utf8.decode(data, allowMalformed: true).trimRight();
      if (text.isNotEmpty) {
        stdout.writeln('[bridge] $text');
      }
    }),
    stderrStream.listen((data) {
      final text = utf8.decode(data, allowMalformed: true).trimRight();
      if (text.isNotEmpty) {
        stderr.writeln('[bridge] $text');
      }
    }),
  ];

  await _waitForBridgeReadiness(process: process, port: port);

  return silentSubscriptions;
}

Future<void> _assertPortAvailable(int port) async {
  if (!await _isPortReachable(port)) {
    return;
  }

  throw StateError('port $port is already in use');
}

Future<void> _waitForBridgeReadiness({
  required Process process,
  required int port,
}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 6));

  while (DateTime.now().isBefore(deadline)) {
    final exitCode = await _tryReadExitCode(process);
    if (exitCode != null) {
      throw StateError('startup process exited early (code: $exitCode)');
    }

    if (await _isPortReachable(port)) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  throw StateError('timeout waiting for bridge on port $port');
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

_ResolvedBridgeConfig _resolveBridgeConfig({required List<String> args}) {
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
  final generatedDir = Directory('$cwd/.dart_tool/flutter_bdd_suite');
  if (!generatedDir.existsSync()) {
    generatedDir.createSync(recursive: true);
  }

  final generatedFile = File('${generatedDir.path}/bridge_runner.dart');
  final setupImport = bridgeSetupPath.replaceAll('\\', '/');

  final content = '''// GENERATED FILE. DO NOT EDIT.
import 'package:flutter_bdd_suite/flutter_bdd_bridge.dart';
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
  late final Process process;

  if (command.isShell) {
    if (Platform.isWindows) {
      process = await Process.start('cmd', ['/c', command.shellCommand!]);
    } else {
      process = await Process.start('/bin/sh', ['-c', command.shellCommand!]);
    }
  } else {
    process = await Process.start(
      command.executable!,
      command.arguments!,
      runInShell: Platform.isWindows,
    );
  }

  final stdoutDone = process.stdout.listen(stdout.add).asFuture<void>();
  final stderrDone = process.stderr.listen(stderr.add).asFuture<void>();

  final exitCode = await process.exitCode;
  await Future.wait([stdoutDone, stderrDone]);
  return exitCode;
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

bool _hasHelpFlag(List<String> args) {
  return args.contains('--help') || args.contains('-h');
}

void _printUsage() {
  stdout.writeln(r'''flutter_bdd_suite CLI

Usage:
  dart run flutter_bdd_suite:cli [cli options] -- [native flutter options]

What this command does:
  1) Generates integration bindings from .feature files.
  2) Executes native Flutter tooling based on --mode.

Wrapper options (consumed before --):
  --config <file>                     Required. File under integration_test/ (e.g. test_config.dart)
  --mode <test|drive>                 Selects internal command: flutter test or flutter drive
  --order <none|alphabetically|basename|reverse|random[:seed]>
  --pattern <regex>
  --tags <expression>
  --dry-run
  --generate-only
  --command <shell>
  --bridge-mode <plain|auto|bridge>
  --bridge-host <host>
  --bridge-port <port>
  --no-bridge
  --no-colors                         Disables ANSI colors
  --show-paths                        Includes file paths and line numbers in output
  --show-stack-traces                 Shows full stack traces for failures
  --bridge-script <path>
  --bridge-setup <path>
  -h, --help

Forwarded options (after --):
  All arguments after -- are passed to native Flutter unchanged.
  Put flutter test/drive flags there, such as:
    --coverage, -d <device>, --web-renderer=html, --driver=..., --target=...

Examples:
  Web (drive mode)
    dart run flutter_bdd_suite:cli --config test_config.dart --mode drive -- \
      --driver test_driver/integration_test.dart \
      --target integration_test/all_integration_tests.dart \
      -d chrome

  Android/iOS/macOS/Linux/Windows (test mode)
    dart run flutter_bdd_suite:cli --mode test --config test_config.dart -- -d macos --coverage
''');
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
    return _ExecutionCommand._(executable: executable, arguments: arguments);
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

  const _BridgeConfig({required this.mode, required this.port});
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

  _ProcessBridgeRuntime({required this.process, required this.subscriptions});

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
