import 'dart:async';

import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_network/peerdeal_network.dart';

class NativeTransportFrameSink implements TransportFrameSink {
  const NativeTransportFrameSink({
    required NativeTransportBridge bridge,
    TransportFrameValidator validator = const BasicTransportFrameValidator(),
  }) : _bridge = bridge,
       _validator = validator;

  final NativeTransportBridge _bridge;
  final TransportFrameValidator _validator;

  @override
  Future<void> sendFrame(TransportFrame frame) async {
    if (!_validator.validate(frame).isValid) {
      throw StateError('Native transport frame rejected.');
    }

    final nativeFrame = _toNativeFrame(frame);
    if (!nativeFrame.isUsable) {
      throw StateError('Native transport frame rejected.');
    }
    final result = await _bridge.sendFrame(nativeFrame);
    if (!result.isSuccess) {
      throw StateError('Native transport send failed.');
    }
  }
}

class NativeTransportFrameDrain {
  const NativeTransportFrameDrain({
    required NativeTransportBridge bridge,
    required TransportFrameReceiver receiver,
    int maxFramesPerDrain = 64,
  }) : _bridge = bridge,
       _receiver = receiver,
       _maxFramesPerDrain = maxFramesPerDrain,
       _unavailableWarnings = null;

  const NativeTransportFrameDrain.unavailable({required List<String> warnings})
    : _bridge = null,
      _receiver = null,
      _maxFramesPerDrain = 0,
      _unavailableWarnings = warnings;

  final NativeTransportBridge? _bridge;
  final TransportFrameReceiver? _receiver;
  final int _maxFramesPerDrain;
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

    if (!_isValidReceiveScope(sessionId) || !_isValidReceiveScope(peerId)) {
      return const NativeTransportFrameDrainResult.unavailable(
        warnings: <String>['Native transport receive scope is invalid.'],
      );
    }
    if (_maxFramesPerDrain < 1) {
      return const NativeTransportFrameDrainResult.unavailable(
        warnings: <String>['Native transport receive batch limit is invalid.'],
      );
    }

    final NativeTransportReceiveSnapshot? snapshot;
    try {
      snapshot = await _awaitOrCancel(
        _bridge!.receiveFrames(sessionId: sessionId, peerId: peerId),
        cancellation,
      );
    } on Object {
      return const NativeTransportFrameDrainResult.unavailable(
        warnings: <String>['Native transport receive failed.'],
      );
    }
    if (snapshot == null) {
      return const NativeTransportFrameDrainResult.unavailable(
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
      try {
        final result = await _awaitOrCancel(
          _receiver!.receive(_fromNativeFrame(frame)),
          cancellation,
        );
        if (result == null) {
          return const NativeTransportFrameDrainResult.unavailable(
            warnings: <String>['Native transport receive cancelled.'],
          );
        }
        results.add(result);
      } on Object {
        results.add(
          const TransportFrameReceiveResult.rejected(
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

  static String _safeNativeWarning(
    String? warning, {
    required String fallback,
  }) {
    if (warning == null || warning.trim().isEmpty) {
      return fallback;
    }
    return 'Native transport reported a platform warning.';
  }

  static bool _isValidReceiveScope(String value) {
    return NativeBridgePayloadLimits.isSafeUtf8Text(
      value,
      NativeBridgePayloadLimits.maxTransportIdentityBytes,
    );
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
      onError: (Object error, StackTrace stackTrace) {
        completeValue(null);
      },
    ),
  );
  return result.future;
}

class NativeTransportFrameDrainResult {
  const NativeTransportFrameDrainResult({
    required this.available,
    required this.results,
    this.warnings = const <String>[],
  });

  const NativeTransportFrameDrainResult.unavailable({
    this.warnings = const <String>[],
  }) : available = false,
       results = const <TransportFrameReceiveResult>[];

  final bool available;
  final List<TransportFrameReceiveResult> results;
  final List<String> warnings;
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
