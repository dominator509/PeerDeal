import 'dart:async';

import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';

import 'native_transport_frame_adapter.dart';

const _defaultPollInterval = Duration(seconds: 1);
const _minimumPollInterval = Duration(milliseconds: 100);
const _maximumPollInterval = Duration(minutes: 1);
const _maximumWarningCount = 4;
const _maximumWarningLength = 160;
const _pollCancellationWarning = 'Native transport source poll cancelled.';

typedef NativeTransportFrameDrainCallback =
    Future<NativeTransportFrameDrainResult> Function();
typedef NativeTransportCancellableFrameDrainCallback =
    Future<NativeTransportFrameDrainResult> Function(Future<void> cancellation);

typedef NativeTransportSourceTimerFactory =
    Timer Function(Duration interval, void Function(Timer timer) callback);

enum AppTableSessionTransportSourceState { idle, running, stopped, disposed }

class AppTableSessionTransportPollResult {
  AppTableSessionTransportPollResult({
    required this.available,
    required this.receivedFrameCount,
    required this.acceptedFrameCount,
    required this.rejectedFrameCount,
    List<String> warnings = const <String>[],
  }) : warnings = _safeTransportSourceWarnings(warnings);

  AppTableSessionTransportPollResult.unavailable({
    List<String> warnings = const <String>[],
  }) : available = false,
       receivedFrameCount = 0,
       acceptedFrameCount = 0,
       rejectedFrameCount = 0,
       warnings = _safeTransportSourceWarnings(warnings);

  final bool available;
  final int receivedFrameCount;
  final int acceptedFrameCount;
  final int rejectedFrameCount;
  final List<String> warnings;

  bool get hasRejectedFrames => rejectedFrameCount > 0;
}

class AppTableSessionTransportSourceStartResult {
  AppTableSessionTransportSourceStartResult({
    required this.started,
    required this.alreadyRunning,
    List<String> warnings = const <String>[],
  }) : warnings = _safeTransportSourceWarnings(warnings);

  AppTableSessionTransportSourceStartResult.started()
    : started = true,
      alreadyRunning = false,
      warnings = const <String>[];

  AppTableSessionTransportSourceStartResult.alreadyRunning()
    : started = false,
      alreadyRunning = true,
      warnings = const <String>[];

  AppTableSessionTransportSourceStartResult.unavailable({
    List<String> warnings = const <String>[],
  }) : started = false,
       alreadyRunning = false,
       warnings = _safeTransportSourceWarnings(warnings);

  final bool started;
  final bool alreadyRunning;
  final List<String> warnings;

  bool get isSuccess => started || alreadyRunning;
}

class AppTableSessionTransportSource {
  AppTableSessionTransportSource({
    required NativeTransportFrameDrainCallback drain,
    NativeTransportCancellableFrameDrainCallback? drainWithCancellation,
    required String sessionId,
    required String peerId,
    Duration pollInterval = _defaultPollInterval,
    NativeTransportSourceTimerFactory? timerFactory,
    Future<void>? cancellation,
  }) : _drain = drain,
       _drainWithCancellation = drainWithCancellation,
       _sessionId = sessionId,
       _peerId = peerId,
       _pollInterval = pollInterval,
       _timerFactory = timerFactory ?? Timer.periodic,
       _cancellation = cancellation {
    final externalCancellation = _cancellation;
    if (externalCancellation != null) {
      unawaited(
        externalCancellation.then<void>(
          (_) {
            _externallyCancelled = true;
            stop();
            _cancelDrain();
          },
          onError: (Object _, StackTrace _) {
            _externallyCancelled = true;
            stop();
            _cancelDrain();
          },
        ),
      );
    }
  }

  final NativeTransportFrameDrainCallback _drain;
  final NativeTransportCancellableFrameDrainCallback? _drainWithCancellation;
  final String _sessionId;
  final String _peerId;
  final Duration _pollInterval;
  final NativeTransportSourceTimerFactory _timerFactory;
  final Future<void>? _cancellation;
  final Completer<void> _disposeCancellation = Completer<void>();
  final Completer<void> _drainCancellation = Completer<void>();

  Timer? _timer;
  Future<AppTableSessionTransportPollResult>? _pollInFlight;
  AppTableSessionTransportSourceState _state =
      AppTableSessionTransportSourceState.idle;
  bool _externallyCancelled = false;
  AppTableSessionTransportPollResult? _lastPoll;

  AppTableSessionTransportSourceState get state => _state;

  AppTableSessionTransportPollResult? get lastPoll => _lastPoll;

  bool get isRunning => _state == AppTableSessionTransportSourceState.running;

  AppTableSessionTransportSourceStartResult start() {
    if (_state == AppTableSessionTransportSourceState.disposed) {
      return AppTableSessionTransportSourceStartResult.unavailable(
        warnings: <String>['Native transport source is disposed.'],
      );
    }
    if (_externallyCancelled) {
      return AppTableSessionTransportSourceStartResult.unavailable(
        warnings: <String>[_pollCancellationWarning],
      );
    }
    if (isRunning) {
      return AppTableSessionTransportSourceStartResult.alreadyRunning();
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
      return AppTableSessionTransportSourceStartResult.started();
    } on Object {
      _timer = null;
      _state = AppTableSessionTransportSourceState.stopped;
      return AppTableSessionTransportSourceStartResult.unavailable(
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
    _cancelDrain();
  }

  Future<AppTableSessionTransportPollResult> pollNow() async {
    if (_state == AppTableSessionTransportSourceState.disposed) {
      return _remember(
        AppTableSessionTransportPollResult.unavailable(
          warnings: <String>['Native transport source is disposed.'],
        ),
      );
    }
    if (_externallyCancelled) {
      return _remember(
        AppTableSessionTransportPollResult.unavailable(
          warnings: <String>[_pollCancellationWarning],
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
      _disposeCancellation.future.then<void>((_) {
        completeValue(
          AppTableSessionTransportPollResult.unavailable(
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
            AppTableSessionTransportPollResult.unavailable(
              warnings: <String>[_pollCancellationWarning],
            ),
          ),
          onError: (Object _, StackTrace _) => completeValue(
            AppTableSessionTransportPollResult.unavailable(
              warnings: <String>[_pollCancellationWarning],
            ),
          ),
        ),
      );
    }

    unawaited(
      future.then<void>(
        completeValue,
        onError: (Object error, StackTrace stackTrace) {
          completeError(error, stackTrace);
        },
      ),
    );

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
      return AppTableSessionTransportPollResult.unavailable(
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
      warnings: _safeTransportSourceWarnings(drainResult.warnings),
    );
  }

  Future<NativeTransportFrameDrainResult?> _loadDrainResult() async {
    try {
      final drainWithCancellation = _drainWithCancellation;
      if (drainWithCancellation != null) {
        return await drainWithCancellation(_drainCancellation.future);
      }
      return await _drain();
    } on Object {
      return null;
    }
  }

  void _cancelDrain() {
    if (!_drainCancellation.isCompleted) {
      _drainCancellation.complete();
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

  static bool _isValidScope(String value) {
    return NativeBridgePayloadLimits.isSafeUtf8Text(
      value,
      NativeBridgePayloadLimits.maxTransportIdentityBytes,
    );
  }
}

List<String> _safeTransportSourceWarnings(List<String> warnings) {
  final truncated = warnings.length > _maximumWarningCount;
  final valueLimit = truncated
      ? _maximumWarningCount - 1
      : _maximumWarningCount;
  final safe = <String>[];
  var lowerLayerTruncated = false;
  for (final warning in warnings) {
    if (safe.length == valueLimit) break;
    final trimmed = warning.trim();
    if (warning == 'Native transport warnings truncated.') {
      lowerLayerTruncated = true;
      continue;
    }
    safe.add(
      trimmed.isEmpty ||
              trimmed != warning ||
              warning.length > _maximumWarningLength ||
              warning.codeUnits.any(
                (unit) => unit < 0x20 || (unit >= 0x7f && unit <= 0x9f),
              )
          ? 'Native transport source warning unavailable.'
          : warning == 'Native transport warning unavailable.'
          ? 'Native transport source warning unavailable.'
          : warning,
    );
  }
  if (truncated || lowerLayerTruncated) {
    safe.add('Native transport source warnings truncated.');
  }
  return List<String>.unmodifiable(safe);
}
