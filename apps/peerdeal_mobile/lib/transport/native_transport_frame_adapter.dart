import 'dart:async';

import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_network/peerdeal_network.dart';

const _maximumWarningCount = 4;
const _maximumWarningLength = 160;

class NativeTransportFrameSink implements TransportFrameSink {
  const NativeTransportFrameSink({
    required NativeTransportBridge bridge,
    Future<void>? cancellation,
    TransportFrameValidator validator = const BasicTransportFrameValidator(
      maxPayloadBytes: NativeBridgePayloadLimits.maxTransportPayloadBytes,
    ),
  }) : _bridge = bridge,
       _cancellation = cancellation,
       _validator = validator;

  final NativeTransportBridge _bridge;
  final Future<void>? _cancellation;
  final TransportFrameValidator _validator;

  @override
  Future<void> sendFrame(TransportFrame frame) async {
    if (await _isCancellationSignaled(_cancellation)) {
      throw StateError('Native transport send cancelled.');
    }
    if (!_validator.validate(frame).isValid) {
      throw StateError('Native transport frame rejected.');
    }

    final nativeFrame = _toNativeFrame(frame);
    if (!nativeFrame.isUsable) {
      throw StateError('Native transport frame rejected.');
    }
    final result = await _awaitOrCancel(
      _sendNativeFrame(nativeFrame),
      _cancellation,
    );
    if (result == null) {
      throw StateError('Native transport send cancelled.');
    }
    if (!result.isSuccess) {
      throw StateError('Native transport send failed.');
    }
  }

  Future<NativeTransportSendResult> _sendNativeFrame(
    NativeTransportFrame frame,
  ) {
    final bridge = _bridge;
    if (bridge is CancellableNativeTransportBridge) {
      final cancellableBridge = bridge as CancellableNativeTransportBridge;
      return cancellableBridge.sendFrame(frame, cancellation: _cancellation);
    }
    return bridge.sendFrame(frame);
  }
}

class NativeTransportFrameDrain {
  const NativeTransportFrameDrain({
    required NativeTransportBridge bridge,
    required TransportFrameReceiver receiver,
    int maxFramesPerDrain = 64,
    Future<void>? cancellation,
  }) : _bridge = bridge,
       _receiver = receiver,
       _maxFramesPerDrain = maxFramesPerDrain,
       _cancellation = cancellation,
       _unavailableWarnings = null;

  NativeTransportFrameDrain.unavailable({required List<String> warnings})
    : _bridge = null,
      _receiver = null,
      _maxFramesPerDrain = 0,
      _cancellation = null,
      _unavailableWarnings = _safeNativeTransportWarnings(
        warnings,
        fallback: 'Native transport warning unavailable.',
      );

  final NativeTransportBridge? _bridge;
  final TransportFrameReceiver? _receiver;
  final int _maxFramesPerDrain;
  final Future<void>? _cancellation;
  final List<String>? _unavailableWarnings;

  Future<NativeTransportFrameDrainResult> drain({
    required String sessionId,
    required String peerId,
    Future<void>? cancellation,
  }) async {
    final unavailableWarnings = _unavailableWarnings;
    if (unavailableWarnings != null) {
      return NativeTransportFrameDrainResult.unavailable(
        warnings: unavailableWarnings,
      );
    }

    if (!_isValidSessionScope(sessionId) || !_isValidPeerScope(peerId)) {
      return NativeTransportFrameDrainResult.unavailable(
        warnings: <String>['Native transport receive scope is invalid.'],
      );
    }
    if (_maxFramesPerDrain < 1 ||
        _maxFramesPerDrain > NativeBridgePayloadLimits.maxTransportFrames) {
      return NativeTransportFrameDrainResult.unavailable(
        warnings: <String>['Native transport receive batch limit is invalid.'],
      );
    }

    final effectiveCancellation = cancellation ?? _cancellation;
    if (await _isCancellationSignaled(effectiveCancellation)) {
      return NativeTransportFrameDrainResult.unavailable(
        warnings: <String>['Native transport receive cancelled.'],
      );
    }

    final NativeTransportReceiveSnapshot? snapshot;
    try {
      snapshot = await _awaitOrCancel(
        _receiveNativeFrames(
          sessionId: sessionId,
          peerId: peerId,
          cancellation: effectiveCancellation,
        ),
        effectiveCancellation,
      );
    } on Object {
      if (await _isCancellationSignaled(effectiveCancellation)) {
        return NativeTransportFrameDrainResult.unavailable(
          warnings: <String>['Native transport receive cancelled.'],
        );
      }
      return NativeTransportFrameDrainResult.unavailable(
        warnings: <String>['Native transport receive failed.'],
      );
    }
    if (snapshot == null) {
      return NativeTransportFrameDrainResult.unavailable(
        warnings: <String>['Native transport receive cancelled.'],
      );
    }
    if (await _isCancellationSignaled(effectiveCancellation)) {
      return NativeTransportFrameDrainResult.unavailable(
        warnings: <String>['Native transport receive cancelled.'],
      );
    }

    if (!snapshot.available) {
      return NativeTransportFrameDrainResult.unavailable(
        warnings: <String>[
          _safeNativeWarning(
            snapshot.warning,
            fallback: 'Native transport receive unavailable.',
          ),
        ],
      );
    }

    final results = <TransportFrameReceiveResult>[];
    for (final frame in snapshot.frames.take(_maxFramesPerDrain)) {
      if (await _isCancellationSignaled(effectiveCancellation)) {
        return NativeTransportFrameDrainResult.unavailable(
          warnings: <String>['Native transport receive cancelled.'],
        );
      }
      if (frame.payloadBytes.length >
          NativeBridgePayloadLimits.maxTransportPayloadBytes) {
        results.add(
          TransportFrameReceiveResult.rejected(
            reasonCode: 'ERR_TRANSPORT_FRAME_REJECTED',
            warnings: const <String>['ERR_TRANSPORT_FRAME_PAYLOAD_TOO_LARGE'],
          ),
        );
        continue;
      }
      try {
        final result = await _awaitOrCancel(
          _receiver!.receive(_fromNativeFrame(frame)),
          effectiveCancellation,
        );
        if (result == null) {
          return NativeTransportFrameDrainResult.unavailable(
            warnings: <String>['Native transport receive cancelled.'],
          );
        }
        results.add(result);
      } on Object {
        if (await _isCancellationSignaled(effectiveCancellation)) {
          return NativeTransportFrameDrainResult.unavailable(
            warnings: <String>['Native transport receive cancelled.'],
          );
        }
        results.add(
          TransportFrameReceiveResult.rejected(
            reasonCode: 'ERR_NATIVE_TRANSPORT_FRAME_RECEIVE_FAILED',
            warnings: <String>['Native transport frame receive failed.'],
          ),
        );
      }
    }

    return NativeTransportFrameDrainResult(
      available: true,
      results: List<TransportFrameReceiveResult>.unmodifiable(results),
      warnings: <String>[
        if (snapshot.warning != null)
          _safeNativeWarning(
            snapshot.warning,
            fallback: 'Native transport receive warning.',
          ),
        if (snapshot.frames.length > _maxFramesPerDrain)
          'Native transport receive batch limit reached.',
      ],
    );
  }

  Future<NativeTransportReceiveSnapshot> _receiveNativeFrames({
    required String sessionId,
    required String peerId,
    required Future<void>? cancellation,
  }) {
    final bridge = _bridge!;
    if (bridge is CancellableNativeTransportBridge) {
      final cancellableBridge = bridge as CancellableNativeTransportBridge;
      return cancellableBridge.receiveFrames(
        sessionId: sessionId,
        peerId: peerId,
        cancellation: cancellation,
      );
    }
    return bridge.receiveFrames(sessionId: sessionId, peerId: peerId);
  }

  static String _safeNativeWarning(
    String? warning, {
    required String fallback,
  }) {
    if (warning == null || warning.trim().isEmpty) {
      return fallback;
    }
    return 'Native transport reported a platform warning.';
  }

  static bool _isValidSessionScope(String value) {
    return NativeBridgePayloadLimits.isSafeUtf8Text(
      value,
      NativeBridgePayloadLimits.maxTransportIdentityBytes,
    );
  }

  static bool _isValidPeerScope(String value) {
    return NetworkInputLimits.isOperationalPeerIdentity(value);
  }
}

Future<T?> _awaitOrCancel<T>(Future<T> operation, Future<void>? cancellation) {
  if (cancellation == null) return operation.then<T?>((value) => value);

  final result = Completer<T?>();
  void completeValue(T? value) {
    if (!result.isCompleted) result.complete(value);
  }

  void completeError(Object error, StackTrace stackTrace) {
    if (!result.isCompleted) result.completeError(error, stackTrace);
  }

  unawaited(
    cancellation.then<void>(
      (_) => completeValue(null),
      onError: (Object error, StackTrace stackTrace) {
        completeValue(null);
      },
    ),
  );
  unawaited(
    operation.then<void>(
      completeValue,
      onError: (Object error, StackTrace stackTrace) {
        completeError(error, stackTrace);
      },
    ),
  );
  return result.future;
}

Future<bool> _isCancellationSignaled(Future<void>? cancellation) async {
  if (cancellation == null) return false;
  return Future.any<bool>(<Future<bool>>[
    cancellation.then<bool>(
      (_) => true,
      onError: (Object error, StackTrace stackTrace) => true,
    ),
    Future<bool>.value(false),
  ]);
}

class NativeTransportFrameDrainResult {
  NativeTransportFrameDrainResult({
    required this.available,
    required List<TransportFrameReceiveResult> results,
    List<String> warnings = const <String>[],
  }) : results = List<TransportFrameReceiveResult>.unmodifiable(results),
       warnings = _safeNativeTransportWarnings(
         warnings,
         fallback: 'Native transport warning unavailable.',
       );

  NativeTransportFrameDrainResult.unavailable({
    List<String> warnings = const <String>[],
  }) : available = false,
       results = const <TransportFrameReceiveResult>[],
       warnings = _safeNativeTransportWarnings(
         warnings,
         fallback: 'Native transport warning unavailable.',
       );

  final bool available;
  final List<TransportFrameReceiveResult> results;
  final List<String> warnings;
}

List<String> _safeNativeTransportWarnings(
  List<String> warnings, {
  required String fallback,
}) {
  final truncated = warnings.length > _maximumWarningCount;
  final valueLimit = truncated
      ? _maximumWarningCount - 1
      : _maximumWarningCount;
  final safe = <String>[];
  for (final warning in warnings) {
    if (safe.length == valueLimit) break;
    final trimmed = warning.trim();
    safe.add(
      trimmed.isEmpty ||
              trimmed != warning ||
              warning.length > _maximumWarningLength ||
              warning.codeUnits.any(
                (unit) => unit < 0x20 || (unit >= 0x7f && unit <= 0x9f),
              )
          ? fallback
          : warning,
    );
  }
  if (truncated) {
    safe.add('Native transport warnings truncated.');
  }
  return List<String>.unmodifiable(safe);
}

NativeTransportFrame _toNativeFrame(TransportFrame frame) {
  return NativeTransportFrame(
    sessionId: frame.sessionId,
    senderPeerId: frame.fromPeerId,
    recipientPeerId: frame.toPeerId,
    sequence: frame.sequence,
    payloadBytes: frame.payload,
  );
}

TransportFrame _fromNativeFrame(NativeTransportFrame frame) {
  return TransportFrame(
    sessionId: frame.sessionId,
    fromPeerId: frame.senderPeerId,
    toPeerId: frame.recipientPeerId,
    sequence: frame.sequence,
    payload: frame.payloadBytes,
  );
}
