import 'dart:async';

import 'package:flutter/services.dart';

import '../native_bridge_payload_limits.dart';
import 'native_transport_bridge.dart';
import 'native_transport_bridge_models.dart';
import 'native_transport_channel_contract.dart';

const _nativeTransportCallTimeout = Duration(seconds: 5);

class MethodChannelNativeTransportBridge
    implements NativeTransportBridge, CancellableNativeTransportBridge {
  MethodChannelNativeTransportBridge({
    MethodChannel? channel,
    Duration timeout = _nativeTransportCallTimeout,
    Future<void>? cancellation,
  }) : _channel = channel ?? const MethodChannel(_channelName),
       _timeout = _validateTimeout(timeout),
       _cancellation = cancellation;

  static const _channelName = NativeTransportChannelContract.channelName;

  final MethodChannel _channel;
  final Duration _timeout;
  final Future<void>? _cancellation;

  @override
  Future<NativeTransportCapability> getCapability({
    Future<void>? cancellation,
  }) async {
    final Map<String, Object?>? result;
    try {
      result = await _invokeWithDeadline(
        () => _channel.invokeMapMethod<String, Object?>(
          NativeTransportChannelContract.getCapabilityMethod,
        ),
        cancellation: cancellation,
      );
    } on _NativeTransportCallCancelled {
      return const NativeTransportCapability.unavailable(
        warning: 'Native transport call cancelled.',
      );
    } on TimeoutException {
      return const NativeTransportCapability.unavailable(
        warning: 'Native transport call timed out.',
      );
    } on MissingPluginException catch (error) {
      return NativeTransportCapability.unavailable(
        warning: _warning('Native transport plugin is unavailable', error),
      );
    } on PlatformException catch (error) {
      return NativeTransportCapability.unavailable(
        warning: _warning('Native transport capability lookup failed', error),
      );
    } on Object catch (error) {
      return NativeTransportCapability.unavailable(
        warning: _warning(
          'Native transport capability payload decode failed',
          error,
        ),
      );
    }

    return NativeTransportChannelContract.decodeCapability(result);
  }

  @override
  Future<NativeTransportSendResult> sendFrame(
    NativeTransportFrame frame, {
    Future<void>? cancellation,
  }) async {
    if (!frame.isUsable) {
      return const NativeTransportSendResult.failure(
        warning: 'Native transport send frame request is invalid.',
      );
    }

    final Map<String, Object?>? result;
    try {
      result = await _invokeWithDeadline(
        () => _channel.invokeMapMethod<String, Object?>(
          NativeTransportChannelContract.sendFrameMethod,
          <String, Object?>{
            'frame': NativeTransportChannelContract.encodeFrame(frame),
          },
        ),
        cancellation: cancellation,
      );
    } on _NativeTransportCallCancelled {
      return const NativeTransportSendResult.failure(
        warning: 'Native transport call cancelled.',
      );
    } on TimeoutException {
      return const NativeTransportSendResult.failure(
        warning: 'Native transport call timed out.',
      );
    } on MissingPluginException catch (error) {
      return NativeTransportSendResult.failure(
        warning: _warning('Native transport plugin is unavailable', error),
      );
    } on PlatformException catch (error) {
      return NativeTransportSendResult.failure(
        warning: _warning('Native transport send failed', error),
      );
    } on Object catch (error) {
      return NativeTransportSendResult.failure(
        warning: _warning('Native transport send result decode failed', error),
      );
    }

    return NativeTransportChannelContract.decodeSendResult(result);
  }

  @override
  Future<NativeTransportReceiveSnapshot> receiveFrames({
    required String sessionId,
    required String peerId,
    Future<void>? cancellation,
  }) async {
    if (!_isValidReceiveScope(sessionId) || !_isValidReceiveScope(peerId)) {
      return const NativeTransportReceiveSnapshot.unavailable(
        warning: 'Native transport receive request is invalid.',
      );
    }

    final Map<String, Object?>? result;
    try {
      result = await _invokeWithDeadline(
        () => _channel.invokeMapMethod<String, Object?>(
          NativeTransportChannelContract.receiveFramesMethod,
          <String, Object?>{'sessionId': sessionId, 'peerId': peerId},
        ),
        cancellation: cancellation,
      );
    } on _NativeTransportCallCancelled {
      return const NativeTransportReceiveSnapshot.unavailable(
        warning: 'Native transport call cancelled.',
      );
    } on TimeoutException {
      return const NativeTransportReceiveSnapshot.unavailable(
        warning: 'Native transport call timed out.',
      );
    } on MissingPluginException catch (error) {
      return NativeTransportReceiveSnapshot.unavailable(
        warning: _warning('Native transport plugin is unavailable', error),
      );
    } on PlatformException catch (error) {
      return NativeTransportReceiveSnapshot.unavailable(
        warning: _warning('Native transport receive failed', error),
      );
    } on Object catch (error) {
      return NativeTransportReceiveSnapshot.unavailable(
        warning: _warning(
          'Native transport receive payload decode failed',
          error,
        ),
      );
    }

    return NativeTransportChannelContract.decodeReceiveSnapshot(result);
  }

  bool _isValidReceiveScope(String value) =>
      NativeBridgePayloadLimits.isSafeUtf8Text(
        value,
        NativeBridgePayloadLimits.maxTransportIdentityBytes,
      );

  static Duration _validateTimeout(Duration timeout) {
    if (timeout.compareTo(Duration.zero) <= 0) {
      throw ArgumentError.value(timeout, 'timeout', 'must be positive');
    }
    return timeout;
  }

  Future<T> _invokeWithDeadline<T>(
    Future<T> Function() operation, {
    Future<void>? cancellation,
  }) {
    final completer = Completer<T>();
    Timer? timer;
    var completed = false;

    void completeValue(T value) {
      if (completed) return;
      completed = true;
      timer?.cancel();
      completer.complete(value);
    }

    void completeError(Object error, StackTrace stackTrace) {
      if (completed) return;
      completed = true;
      timer?.cancel();
      completer.completeError(error, stackTrace);
    }

    timer = Timer(
      _timeout,
      () => completeError(
        TimeoutException('Native transport call timed out.', _timeout),
        StackTrace.current,
      ),
    );
    final cancellationSignals = <Future<void>>[];
    if (_cancellation case final cancellationSignal?) {
      cancellationSignals.add(cancellationSignal);
    }
    if (cancellation case final cancellationSignal?) {
      cancellationSignals.add(cancellationSignal);
    }
    for (final cancellationSignal in cancellationSignals) {
      unawaited(
        cancellationSignal.then<void>(
          (_) => completeError(
            const _NativeTransportCallCancelled(),
            StackTrace.current,
          ),
          onError: (Object _, StackTrace _) => completeError(
            const _NativeTransportCallCancelled(),
            StackTrace.current,
          ),
        ),
      );
    }
    void startOperation() {
      if (completed) return;
      try {
        unawaited(
          operation().then<void>(
            completeValue,
            onError: (Object error, StackTrace stackTrace) {
              completeError(error, stackTrace);
            },
          ),
        );
      } on Object catch (error, stackTrace) {
        completeError(error, stackTrace);
      }
    }

    scheduleMicrotask(startOperation);
    return completer.future;
  }

  String _warning(String prefix, Object error) {
    if (error is PlatformException) {
      return '$prefix: ${error.code} ${error.message ?? ''}'.trim();
    }
    return '$prefix: $error';
  }
}

final class _NativeTransportCallCancelled implements Exception {
  const _NativeTransportCallCancelled();
}
