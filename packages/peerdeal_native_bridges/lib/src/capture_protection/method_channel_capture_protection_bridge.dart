import 'dart:async';

import 'package:flutter/services.dart';

import 'capture_protection_channel_contract.dart';
import 'capture_protection_bridge.dart';
import 'capture_protection_bridge_models.dart';

const _captureProtectionCallTimeout = Duration(seconds: 5);

class MethodChannelCaptureProtectionBridge
    implements
        CaptureProtectionBridge,
        CancellableCaptureProtectionBridge,
        CaptureProtectionActionBridge,
        CancellableCaptureProtectionActionBridge {
  MethodChannelCaptureProtectionBridge({
    MethodChannel? channel,
    Duration timeout = _captureProtectionCallTimeout,
  }) : _channel = channel ?? const MethodChannel(_channelName),
       _timeout = _validateTimeout(timeout);

  static const _channelName = CaptureProtectionChannelContract.channelName;

  final MethodChannel _channel;
  final Duration _timeout;

  @override
  Future<CaptureProtectionCapability> getCapability({
    Future<void>? cancellation,
  }) async {
    final Map<String, Object?>? result;
    try {
      result = await _invokeWithDeadline(
        () => _channel.invokeMapMethod<String, Object?>('getCapability'),
        cancellation: cancellation,
      );
    } on _CaptureProtectionCallCancelled {
      return const CaptureProtectionCapability.unavailable(
        warning: 'Capture protection call cancelled.',
      );
    } on TimeoutException {
      return const CaptureProtectionCapability.unavailable(
        warning: 'Capture protection call timed out.',
      );
    } on MissingPluginException catch (error) {
      return CaptureProtectionCapability.unavailable(
        warning: _warning('Capture protection plugin is unavailable', error),
      );
    } on PlatformException catch (error) {
      return CaptureProtectionCapability.unavailable(
        warning: _warning('Capture protection capability lookup failed', error),
      );
    } on Object catch (error) {
      return CaptureProtectionCapability.unavailable(
        warning: _warning('Capture protection payload decode failed', error),
      );
    }

    return CaptureProtectionChannelContract.decodeCapability(result);
  }

  @override
  Future<CaptureProtectionActionResult> setBlocking({
    required bool enabled,
    Future<void>? cancellation,
  }) async {
    final Map<String, Object?>? result;
    try {
      result = await _invokeWithDeadline(
        () => _channel.invokeMapMethod<String, Object?>(
          CaptureProtectionChannelContract.setBlockingMethod,
          CaptureProtectionChannelContract.encodeBlockingRequest(
            enabled: enabled,
          ),
        ),
        cancellation: cancellation,
      );
    } on _CaptureProtectionCallCancelled {
      return const CaptureProtectionActionResult.failure(
        warning: 'Capture protection call cancelled.',
      );
    } on TimeoutException {
      return const CaptureProtectionActionResult.failure(
        warning: 'Capture protection call timed out.',
      );
    } on MissingPluginException catch (error) {
      return CaptureProtectionActionResult.failure(
        warning: _warning('Capture protection plugin is unavailable', error),
      );
    } on PlatformException catch (error) {
      return CaptureProtectionActionResult.failure(
        warning: _warning('Capture protection action failed', error),
      );
    } on Object catch (error) {
      return CaptureProtectionActionResult.failure(
        warning: _warning('Capture protection action decode failed', error),
      );
    }

    return CaptureProtectionChannelContract.decodeActionResult(result);
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
        TimeoutException('Capture protection call timed out.', _timeout),
        StackTrace.current,
      ),
    );
    if (cancellation != null) {
      unawaited(
        cancellation.then<void>(
          (_) => completeError(
            const _CaptureProtectionCallCancelled(),
            StackTrace.current,
          ),
          onError: (Object _, StackTrace _) => completeError(
            const _CaptureProtectionCallCancelled(),
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

  static Duration _validateTimeout(Duration timeout) {
    if (timeout.compareTo(Duration.zero) <= 0) {
      throw ArgumentError.value(timeout, 'timeout', 'must be positive');
    }
    return timeout;
  }

  String _warning(String prefix, Object error) {
    if (error is PlatformException) {
      final message = error.message;
      return message == null || message.isEmpty
          ? '$prefix: ${error.code}.'
          : '$prefix: ${error.code} - $message';
    }
    return '$prefix: $error';
  }
}

final class _CaptureProtectionCallCancelled implements Exception {
  const _CaptureProtectionCallCancelled();
}
