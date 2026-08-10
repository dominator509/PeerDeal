import '../session/app_holdem_table_session_runtime.dart';
import '../session/app_table_session_runtime.dart';
import 'app_table_session_transport_handler.dart';
import 'app_table_session_transport_source.dart';
import 'native_transport_session_factory.dart';

class AppTableSessionTransportProvisioner {
  AppTableSessionTransportProvisioner({
    required AppTableSessionRuntime runtime,
    AppHoldemTableSessionRuntime? holdemRuntime,
    NativeTransportSessionFactory? nativeSessionFactory,
    Duration pollInterval = const Duration(seconds: 1),
    NativeTransportSourceTimerFactory? timerFactory,
  }) : _runtime = runtime,
       _holdemRuntime = holdemRuntime,
       _nativeSessionFactory =
           nativeSessionFactory ?? NativeTransportSessionFactory(),
       _pollInterval = pollInterval,
       _timerFactory = timerFactory;

  final AppTableSessionRuntime _runtime;
  final AppHoldemTableSessionRuntime? _holdemRuntime;
  final NativeTransportSessionFactory _nativeSessionFactory;
  final Duration _pollInterval;
  final NativeTransportSourceTimerFactory? _timerFactory;

  Future<AppTableSessionTransportProvisionResult> load({
    required String peerId,
  }) async {
    if (!_isValidIdentity(peerId)) {
      return const AppTableSessionTransportProvisionResult.unavailable(
        warnings: <String>['Native transport peer identity is invalid.'],
      );
    }

    final handler = AppTableSessionTransportHandler(
      runtime: _runtime,
      holdemRuntime: _holdemRuntime,
    );
    NativeTransportSessionLoadResult loaded;
    try {
      loaded = await _nativeSessionFactory.loadSession(handler: handler);
    } on Object {
      return const AppTableSessionTransportProvisionResult.unavailable(
        warnings: <String>['Native transport session could not be loaded.'],
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

  static bool _isValidIdentity(String value) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty &&
        trimmed == value &&
        !value.codeUnits.any((unit) => unit < 0x20 || unit == 0x7f);
  }

  static List<String> _safeWarnings(
    Iterable<String> warnings, {
    required String fallback,
  }) {
    const maximumWarningCount = 4;
    const maximumWarningLength = 160;
    final safe = <String>[];
    for (final warning in warnings) {
      if (safe.length == maximumWarningCount) break;
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
    return List<String>.unmodifiable(safe);
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
  }) : warnings = List<String>.unmodifiable(warnings);

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

  const AppTableSessionTransportProvisionResult.unavailable({
    this.warnings = const <String>[],
  }) : available = false,
       runtime = null,
       handler = null,
       session = null,
       source = null;

  final bool available;
  final AppTableSessionRuntime? runtime;
  final AppTableSessionTransportHandler? handler;
  final NativeTransportSession? session;
  final AppTableSessionTransportSource? source;
  final List<String> warnings;
}
