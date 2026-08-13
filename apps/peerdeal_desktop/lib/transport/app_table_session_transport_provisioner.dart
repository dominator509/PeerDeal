import 'dart:async';

import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';

import '../session/app_holdem_table_session_runtime.dart';
import '../session/app_table_session_runtime.dart';
import 'app_table_session_transport_handler.dart';
import 'app_table_session_transport_source.dart';
import 'native_transport_session_factory.dart';

class AppTableSessionTransportProvisioner {
  AppTableSessionTransportProvisioner({
    required AppTableSessionRuntime runtime,
    AppHoldemTableSessionRuntime? holdemRuntime,
    AppTableSessionEventObserver? onEventAccepted,
    NativeTransportSessionFactory? nativeSessionFactory,
    Duration pollInterval = const Duration(seconds: 1),
    NativeTransportSourceTimerFactory? timerFactory,
    Future<void>? cancellation,
  }) : _runtime = runtime,
       _holdemRuntime = holdemRuntime,
       _onEventAccepted = onEventAccepted,
       _nativeSessionFactory =
           nativeSessionFactory ??
           NativeTransportSessionFactory(cancellation: cancellation),
       _pollInterval = pollInterval,
       _timerFactory = timerFactory,
       _cancellation = cancellation;

  final AppTableSessionRuntime _runtime;
  final AppHoldemTableSessionRuntime? _holdemRuntime;
  final AppTableSessionEventObserver? _onEventAccepted;
  final NativeTransportSessionFactory _nativeSessionFactory;
  final Duration _pollInterval;
  final NativeTransportSourceTimerFactory? _timerFactory;
  final Future<void>? _cancellation;

  Future<AppTableSessionTransportProvisionResult> load({
    required String peerId,
  }) async {
    if (!_isValidIdentity(peerId)) {
      return AppTableSessionTransportProvisionResult.unavailable(
        warnings: <String>['Native transport peer identity is invalid.'],
      );
    }

    final handler = AppTableSessionTransportHandler(
      runtime: _runtime,
      holdemRuntime: _holdemRuntime,
      onEventAccepted: _onEventAccepted,
    );
    NativeTransportSessionLoadResult loaded;
    try {
      final loadedResult = await _loadSession(handler: handler);
      if (loadedResult == null) {
        return AppTableSessionTransportProvisionResult.unavailable(
          warnings: <String>['Native transport session load cancelled.'],
        );
      }
      loaded = loadedResult;
    } on Object {
      return AppTableSessionTransportProvisionResult.unavailable(
        warnings: <String>['Native transport session could not be loaded.'],
      );
    }

    if (await _isCancellationSignaled()) {
      return AppTableSessionTransportProvisionResult.unavailable(
        warnings: <String>['Native transport session load cancelled.'],
      );
    }

    final session = loaded.session;
    if (!loaded.available || session == null) {
      return AppTableSessionTransportProvisionResult.unavailable(
        warnings: _safeWarnings(
          loaded.warnings,
          fallback: 'Native transport session unavailable.',
        ),
      );
    }

    final source = session.createSource(
      sessionId: _runtime.state.sessionId,
      peerId: peerId,
      pollInterval: _pollInterval,
      timerFactory: _timerFactory,
      cancellation: _cancellation,
    );
    return AppTableSessionTransportProvisionResult.available(
      runtime: _runtime,
      handler: handler,
      session: session,
      source: source,
      warnings: _safeWarnings(
        loaded.warnings,
        fallback: 'Native transport session warning unavailable.',
      ),
    );
  }

  Future<NativeTransportSessionLoadResult?> _loadSession({
    required AppTableSessionTransportHandler handler,
  }) async {
    final operation = _nativeSessionFactory.loadSession(handler: handler);
    final cancellation = _cancellation;
    if (cancellation == null) return operation;

    final result = Completer<NativeTransportSessionLoadResult?>();
    void completeValue(NativeTransportSessionLoadResult? value) {
      if (!result.isCompleted) result.complete(value);
    }

    void completeError(Object error, StackTrace stackTrace) {
      if (!result.isCompleted) result.completeError(error, stackTrace);
    }

    unawaited(
      operation.then<void>(
        completeValue,
        onError: (Object error, StackTrace stackTrace) {
          completeError(error, stackTrace);
        },
      ),
    );
    unawaited(
      cancellation.then<void>(
        (_) => completeValue(null),
        onError: (Object _, StackTrace _) => completeValue(null),
      ),
    );
    return result.future;
  }

  Future<bool> _isCancellationSignaled() async {
    final cancellation = _cancellation;
    if (cancellation == null) return false;

    var signaled = false;
    cancellation.then<void>(
      (_) => signaled = true,
      onError: (Object _, StackTrace _) => signaled = true,
    );
    await Future<void>.value();
    return signaled;
  }

  static bool _isValidIdentity(String value) {
    return NativeBridgePayloadLimits.isSafeUtf8Text(
      value,
      NativeBridgePayloadLimits.maxTransportIdentityBytes,
    );
  }

  static List<String> _safeWarnings(
    List<String> warnings, {
    required String fallback,
  }) {
    return _safeTransportProvisionWarnings(warnings, fallback: fallback);
  }
}

class AppTableSessionTransportProvisionResult {
  AppTableSessionTransportProvisionResult({
    required this.available,
    this.runtime,
    this.handler,
    this.session,
    this.source,
    List<String> warnings = const <String>[],
  }) : warnings = _safeTransportProvisionWarnings(
         warnings,
         fallback: 'Native transport session warning unavailable.',
       );

  AppTableSessionTransportProvisionResult.available({
    required AppTableSessionRuntime runtime,
    required AppTableSessionTransportHandler handler,
    required NativeTransportSession session,
    required AppTableSessionTransportSource source,
    List<String> warnings = const <String>[],
  }) : this(
         available: true,
         runtime: runtime,
         handler: handler,
         session: session,
         source: source,
         warnings: warnings,
       );

  AppTableSessionTransportProvisionResult.unavailable({
    List<String> warnings = const <String>[],
  }) : available = false,
       runtime = null,
       handler = null,
       session = null,
       source = null,
       warnings = _safeTransportProvisionWarnings(
         warnings,
         fallback: 'Native transport session warning unavailable.',
       );

  final bool available;
  final AppTableSessionRuntime? runtime;
  final AppTableSessionTransportHandler? handler;
  final NativeTransportSession? session;
  final AppTableSessionTransportSource? source;
  final List<String> warnings;
}

List<String> _safeTransportProvisionWarnings(
  List<String> warnings, {
  required String fallback,
}) {
  const maximumWarningCount = 4;
  const maximumWarningLength = 160;
  final truncated = warnings.length > maximumWarningCount;
  final valueLimit = truncated ? maximumWarningCount - 1 : maximumWarningCount;
  final safe = <String>[];
  for (final warning in warnings) {
    if (safe.length == valueLimit) break;
    final trimmed = warning.trim();
    safe.add(
      trimmed.isEmpty ||
              trimmed != warning ||
              warning.length > maximumWarningLength ||
              warning.codeUnits.any((unit) => unit < 0x20 || unit == 0x7f)
          ? fallback
          : warning,
    );
  }
  if (truncated) {
    safe.add('Native transport session warnings truncated.');
  }
  return List<String>.unmodifiable(safe);
}
