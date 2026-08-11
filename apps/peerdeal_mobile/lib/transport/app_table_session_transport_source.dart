import 'dart:async';

import 'native_transport_frame_adapter.dart';

const _defaultPollInterval = Duration(seconds: 1);
const _minimumPollInterval = Duration(milliseconds: 100);
const _maximumPollInterval = Duration(minutes: 1);
const _maximumWarningCount = 4;
const _maximumWarningLength = 160;
const _pollCancellationWarning = 'Native transport source poll cancelled.';

typedef NativeTransportFrameDrainCallback =
    Future<NativeTransportFrameDrainResult> Function();

typedef NativeTransportSourceTimerFactory =
    Timer Function(Duration interval, void Function(Timer timer) callback);

enum AppTableSessionTransportSourceState { idle, running, stopped, disposed }

class AppTableSessionTransportPollResult {
  const AppTableSessionTransportPollResult({
    required this.available,
    required this.receivedFrameCount,
    required this.acceptedFrameCount,
    required this.rejectedFrameCount,
    this.warnings = const <String>[],
  });

  const AppTableSessionTransportPollResult.unavailable({
    this.warnings = const <String>[],
  }) : available = false,
       receivedFrameCount = 0,
       acceptedFrameCount = 0,
       rejectedFrameCount = 0;

  final bool available;
  final int receivedFrameCount;
  final int acceptedFrameCount;
  final int rejectedFrameCount;
  final List<String> warnings;

  bool get hasRejectedFrames => rejectedFrameCount > 0;
}

class AppTableSessionTransportSourceStartResult {
  const AppTableSessionTransportSourceStartResult({
    required this.started,
    required this.alreadyRunning,
    this.warnings = const <String>[],
  });

  const AppTableSessionTransportSourceStartResult.started()
    : started = true,
      alreadyRunning = false,
      warnings = const <String>[];

  const AppTableSessionTransportSourceStartResult.alreadyRunning()
    : started = false,
      alreadyRunning = true,
      warnings = const <String>[];

  const AppTableSessionTransportSourceStartResult.unavailable({
    this.warnings = const <String>[],
  }) : started = false,
       alreadyRunning = false;

  final bool started;
  final bool alreadyRunning;
  final List<String> warnings;

  bool get isSuccess => started || alreadyRunning;
}

class AppTableSessionTransportSource {
  AppTableSessionTransportSource({
    required NativeTransportFrameDrainCallback drain,
    required String sessionId,
    required String peerId,
    Duration pollInterval = _defaultPollInterval,
    NativeTransportSourceTimerFactory? timerFactory,
    Future<void>? cancellation,
  }) : _drain = drain,
       _sessionId = sessionId,
       _peerId = peerId,
       _pollInterval = pollInterval,
       _timerFactory = timerFactory ?? Timer.periodic,
       _cancellation = cancellation;

  final NativeTransportFrameDrainCallback _drain;
  final String _sessionId;
  final String _peerId;
  final Duration _pollInterval;
  final NativeTransportSourceTimerFactory _timerFactory;
  final Future<void>? _cancellation;
  final Completer<void> _disposeCancellation = Completer<void>();

  Timer? _timer;
  Future<AppTableSessionTransportPollResult>? _pollInFlight;
  AppTableSessionTransportSourceState _state =
      AppTableSessionTransportSourceState.idle;
  AppTableSessionTransportPollResult? _lastPoll;

  AppTableSessionTransportSourceState get state => _state;

  AppTableSessionTransportPollResult? get lastPoll => _lastPoll;

  bool get isRunning => _state == AppTableSessionTransportSourceState.running;

  AppTableSessionTransportSourceStartResult start() {
    if (_state == AppTableSessionTransportSourceState.disposed) {
      return const AppTableSessionTransportSourceStartResult.unavailable(
        warnings: <String>['Native transport source is disposed.'],
      );
    }
    if (isRunning) {
      return const AppTableSessionTransportSourceStartResult.alreadyRunning();
    }

    final configurationError = _configurationError;
    if (configurationError != null) {
      return AppTableSessionTransportSourceStartResult.unavailable(
        warnings: <String>[configurationError],
      );
    }

    try {
      _timer = _timerFactory(_pollInterval, (_) {
        if (isRunning) unawaited(pollNow());
      });
      _state = AppTableSessionTransportSourceState.running;
      unawaited(pollNow());
      return const AppTableSessionTransportSourceStartResult.started();
    } on Object {
      _timer = null;
      _state = AppTableSessionTransportSourceState.stopped;
      return const AppTableSessionTransportSourceStartResult.unavailable(
        warnings: <String>['Native transport source could not start.'],
      );
    }
  }

  void stop() {
    if (_state == AppTableSessionTransportSourceState.disposed) return;
    _timer?.cancel();
    _timer = null;
    _state = AppTableSessionTransportSourceState.stopped;
  }

  void dispose() {
    if (_state == AppTableSessionTransportSourceState.disposed) return;
    stop();
    _state = AppTableSessionTransportSourceState.disposed;
    if (!_disposeCancellation.isCompleted) {
      _disposeCancellation.complete();
    }
  }

  Future<AppTableSessionTransportPollResult> pollNow() async {
    if (_state == AppTableSessionTransportSourceState.disposed) {
      return _remember(
        const AppTableSessionTransportPollResult.unavailable(
          warnings: <String>['Native transport source is disposed.'],
        ),
      );
    }

    final inFlight = _pollInFlight;
    if (inFlight != null) return _observePoll(inFlight);

    final future = _poll();
    _pollInFlight = future;
    unawaited(_releasePollWhenSettled(future));
    return _observePoll(future);
  }

  Future<void> _releasePollWhenSettled(
    Future<AppTableSessionTransportPollResult> future,
  ) async {
    try {
      await future;
    } on Object {
      // The observer owns the visible failure result; this cleanup only keeps
      // the underlying drain registered until it has actually settled.
    }
    if (identical(_pollInFlight, future)) {
      _pollInFlight = null;
    }
  }

  Future<AppTableSessionTransportPollResult> _observePoll(
    Future<AppTableSessionTransportPollResult> future,
  ) async {
    final observed = Completer<AppTableSessionTransportPollResult>();

    void completeValue(AppTableSessionTransportPollResult value) {
      if (!observed.isCompleted) observed.complete(value);
    }

    void completeError(Object error, StackTrace stackTrace) {
      if (!observed.isCompleted) observed.completeError(error, stackTrace);
    }

    unawaited(
      future.then<void>(
        completeValue,
        onError: (Object error, StackTrace stackTrace) {
          completeError(error, stackTrace);
        },
      ),
    );
    unawaited(
      _disposeCancellation.future.then<void>((_) {
        completeValue(
          const AppTableSessionTransportPollResult.unavailable(
            warnings: <String>[_pollCancellationWarning],
          ),
        );
      }),
    );

    final cancellation = _cancellation;
    if (cancellation != null) {
      unawaited(
        cancellation.then<void>(
          (_) => completeValue(
            const AppTableSessionTransportPollResult.unavailable(
              warnings: <String>[_pollCancellationWarning],
            ),
          ),
          onError: (Object _, StackTrace _) => completeValue(
            const AppTableSessionTransportPollResult.unavailable(
              warnings: <String>[_pollCancellationWarning],
            ),
          ),
        ),
      );
    }

    return _remember(await observed.future);
  }

  Future<AppTableSessionTransportPollResult> _poll() async {
    final configurationError = _configurationError;
    if (configurationError != null) {
      return AppTableSessionTransportPollResult.unavailable(
        warnings: <String>[configurationError],
      );
    }

    final drainResult = await _loadDrainResult();
    if (drainResult == null) {
      return const AppTableSessionTransportPollResult.unavailable(
        warnings: <String>['Native transport source poll failed.'],
      );
    }

    var acceptedFrameCount = 0;
    var rejectedFrameCount = 0;
    for (final result in drainResult.results) {
      if (result.accepted) {
        acceptedFrameCount += 1;
      } else {
        rejectedFrameCount += 1;
      }
    }

    return AppTableSessionTransportPollResult(
      available: drainResult.available,
      receivedFrameCount: drainResult.results.length,
      acceptedFrameCount: acceptedFrameCount,
      rejectedFrameCount: rejectedFrameCount,
      warnings: _safeWarnings(drainResult.warnings),
    );
  }

  Future<NativeTransportFrameDrainResult?> _loadDrainResult() async {
    try {
      return await _drain();
    } on Object {
      return null;
    }
  }

  AppTableSessionTransportPollResult _remember(
    AppTableSessionTransportPollResult result,
  ) {
    _lastPoll = result;
    return result;
  }

  String? get _configurationError {
    if (!_isValidScope(_sessionId) || !_isValidScope(_peerId)) {
      return 'Native transport source scope is invalid.';
    }
    if (_pollInterval < _minimumPollInterval ||
        _pollInterval > _maximumPollInterval) {
      return 'Native transport source poll interval is invalid.';
    }
    return null;
  }

  static List<String> _safeWarnings(List<String> warnings) {
    final safe = <String>[];
    for (final warning in warnings) {
      if (safe.length == _maximumWarningCount) break;
      final trimmed = warning.trim();
      if (trimmed.isEmpty ||
          trimmed != warning ||
          _hasControlCharacter(warning)) {
        safe.add('Native transport source warning unavailable.');
        continue;
      }
      safe.add(
        warning.length > _maximumWarningLength
            ? 'Native transport source warning unavailable.'
            : warning,
      );
    }
    return List<String>.unmodifiable(safe);
  }

  static bool _isValidScope(String value) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty &&
        trimmed == value &&
        !_hasControlCharacter(value);
  }

  static bool _hasControlCharacter(String value) {
    return value.codeUnits.any((unit) => unit < 0x20 || unit == 0x7f);
  }
}
